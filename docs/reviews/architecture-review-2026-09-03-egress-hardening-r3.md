# Architecture Review — egress hardening pass 3, 2839e59..1434fc9

Commit: 1434fc9

**Scope:** `git diff 2839e59..1434fc9 -- devcontainer-config/` — `init-firewall.sh` (+60 net, 1027 → 1087), `Dockerfile` (three hunks: the `/usr/local/share` chown narrowing, the uv comment, the `cc-egress` chown), `cc-sni-proxy.py` (+3 net, 312 → 315: `log()` docstring, one `FAIL` message reworded) — plus one file outside `devcontainer-config/` read as the answer to r2's A1: the new bats case `every regular file in install.sh's PAYLOAD is hashed by enforcement_files` (`test/cc-isolated-functions.bats:496-509`). Read as committed context but not themselves reviewed: `test/init-firewall-rules.bats` (+74/−6, six new cases and two stub knobs), `docs/working/questions.md` (two new rows), `devcontainer-config/cc-isolated.sh`, `devcontainer-config/install.sh`, `docs/decisions/log.md` row 42.
**Date:** 2026-09-03
**Based on:** `docs/reviews/architecture-review-2026-09-03-egress-hardening-r2.md` (on `2839e59`, findings A1–A8) and `docs/reviews/code-fact-check-report.md` (loop-pass k=1 on `6eaa9a0`: 16 Verified, 1 Stale — fixed in `1434fc9` — 1 Mostly accurate; lock placement, the ownership assertion's position after the traps, and the unconditional `IP6_FILTER` assignment all verified, and not re-verified here).

**Trust-boundary cross-reference:** `docs/reviews/security-review-2026-09-03-egress-hardening-r3.md` did not exist when the findings below were drafted; it landed before this report was filed, and its Trust Boundary Map labels are cross-referenced here without the findings being rewritten around them. Its boundaries are numbered `B1`–`B6` and its findings `N1`–`N5`; mine are `B1`–`B8`. To avoid the collision, every reference below is written as **sec-B<n>** or **sec-N<n>**.

| My finding | Security r3 label | Relation |
|---|---|---|
| B2 (`claude-home` unhashed) | **sec-B2** — host-side config dir → `check_manifest()` → image build, marked *"unchanged this range"* | Same boundary. Their map does not flag the `claude-home` gap inside it; mine is the structural read of the same edge. |
| B3 (lock brackets phase B only) | **sec-N1** (Low), **sec-B6**, **sec-S4** | Independent convergence. They name the same residual — *"a second run's phase A resolves against a mid-rebuild network"* — and their open question ("load-bearing latency fix, or opportunistic?") is the right one to settle before either fix. |
| B4 (hooks run ahead of the ownership assertion) | **sec-N5**, **sec-B3**, **sec-S9** | Their read is stronger: the `--print-*` hooks take a caller-supplied path and the sudoers grant names no arguments, so the seam is also a root-privileged read primitive. Structurally the seam is still where it should be; the fix belongs in sudoers, not in the seam. |
| B5 (`CC_EGRESS_DIR` disables an assertion) | **sec-N4** (Low, *"the one I would fix first"*) | Same finding from two directions — they call it *"an assertion whose skip condition is weaker than the assertion"*. Their remedy (assert `env_reset`/no-`SETENV` in the sudoers file) and mine (compare `$EGRESS_DIR` to the default) are complementary, not alternatives. |
| B7 (`-A`/`-C` literal pair) | **sec-N2** — four *more* `-C` assertions wanted for `CC_SNI_GUARD` / `CC_DNS_GUARD` | Strengthens the recommendation: if the count of copies is about to go from two to six, the shared match array stops being optional legibility. |
| B8 (`"all the way up"` vs. two levels) | **sec-B3a**, marked ✓ CLOSED | They read the assertion as closing the Critical. I agree on substance; my finding is the comment/implementation mismatch only, and their close is the reason it is Minor. |

No structural finding below is contradicted by their map, and none of their five findings is above Low.

---

### Prior findings status

| Prior # | Finding (r2) | Status | Evidence |
|---|---|---|---|
| A1 | Four hand-maintained copies of the enforcement-file list, none cross-checked | **partially closed → new residue (B1)** | `test/cc-isolated-functions.bats:496-509` adds the cross-check r2 asked for, in one of the two directions it asked for: `PAYLOAD ∖ {directories} ⊆ enforcement_files()`. The `{Dockerfile COPY sources} ⊆ PAYLOAD` direction — the one that produced F1's build break — is not covered (`grep -rn 'COPY' test/` returns nothing). The exclusion is `[ -d "$CONFIG_SRC/$item" ] && continue`, not a named list. Test passes here; fails on a clean checkout (B1). |
| A2 | `claude-home/` → `/opt/claude-workflows` (104 files, `*.sh`/`*.py` at 0555) outside the bless manifest while the comment above `enforcement_files()` claims full coverage | **open — the one Structural finding still open (B2)** | `cc-isolated.sh:44-52` comment unchanged; `enforcement_files()` `:53-70` unchanged; `docs/working/questions.md:16` row unchanged and still unchecked; `docs/decisions/log.md` untouched in this range. The new bats case adds a *third*, weakest encoding of the exclusion ("it is a directory on this machine"). |
| A3 | The negative probe made the firewall a parser of the proxy's log grammar and of its truncate-on-start semantics — undeclared contract | **partially closed (B6)** | `cc-sni-proxy.py:157-161` — `log()` now carries `CONTRACT: init-firewall.sh's verification probe greps this log for REJECT sni=<name> orig_dst=<ip>:<port>`. Declared at the **producer**; r2 asked for it at the consumer. `init-firewall.sh:1068-1073` gained three comment lines about the `orig_dst` discriminator but never names the grammar as a contract, and the truncate-on-start half (`daemonize`, `:250`, `O_TRUNC`) is still declared only in `--log`'s argparse help at `:303`. The dependency on truncation *grew* in this range, not shrank (see B6). |
| A4 | Two identical hostname regexes kept equal by comment; `compose_dnsmasq_conf` re-parses raw entries; `Allowlist.load` unvalidated | **mostly closed; two residues carried** | `HOST_LABEL`/`HOST_RE` at `:129-130`, consumed at `:140` (`parse_entry`) and `:221` (`compose_dnsmasq_conf`) — one literal, two consumers, and the shared form was *tightened* to `(\.…)+` so a single label is now rejected on both sides (`test/init-firewall-rules.bats:853-865` inverts the old test). Residues: `compose_dnsmasq_conf` still receives raw `ALLOWED_DOMAINS` (`:772`) and re-derives with `${d%%:*}` at `:217`, still reads `GITHUB_DNS_ZONES` as a global, and `cc-sni-proxy.py:133-142` `Allowlist.load` is byte-for-byte unchanged. See Q3 under Dependency Map. |
| A5 | `CC_FIREWALL_PATH` shares the "tests only" override convention with file-relocation overrides but selects every root-executed binary | **open, and the family gained a second risk class (B5)** | `init-firewall.sh:31-38` unchanged; no test marker, no sudoers assertion. New in this range: `CC_EGRESS_DIR`'s *presence* now disables a boundary assertion (`:308`), and `CC_FIREWALL_LOCK_WAIT` is now the only override in the family that gets validated (`:538`). |
| A6 | `9>&-` is a per-call-site obligation at two daemon starts because F5's lifecycle helper was never factored | **open, unchanged** | `:785` (dnsmasq) and `:994` (proxy) still each carry `9>&-`; no `start_or_restart` helper; the lock block's comment (`:523-535`) still does not state the obligation at `exec 9>` (`:540`), which was r2's interim recommendation. `stop_dnsmasq` (`:456`) and `stop_prior` (`cc-sni-proxy.py:219`) still differ. |
| A7 | IPv6 capability probe sat in phase B, breaking the phase-A precondition convention; only warn-and-continue control in the script | **closed, and closed better than filed** | The probe moved to `:500-517`, under a `# --- IPv6 preconditions (see the IPv6 block in phase B) ---` banner that now matches the dnsmasq (`:432`) and SNI (`:473`) banners verbatim in form — three instances make it a convention rather than a coincidence. `IP6_FILTER` is assigned unconditionally at `:509` and consumed at `:582`. The warn-and-continue path survives but its blast radius is now bounded by construction: `:512-516` makes "no filter table AND a global IPv6 address" fatal *before the flush*, so the remaining warning can only fire when there is nothing to filter. r2's second half (surface the degraded case in the success line) was not taken and no longer matters much. |
| A8 | The eventual F6 split: prerequisite de-risked, subject grew, hook seam intact | **informational, unchanged in kind** | 1027 → 1087 lines. All four `--print-*` hooks (`:76`, `:108`, `:156`, `:232`) still exit ahead of the trap (`:299`), the ownership assertion (`:308`) and the lock (`:540`), so a test invocation still cannot take the lock, trip the assertion, or alter the boundary. The extraction unit for the composition lib grew by two globals (`HOST_LABEL`, `HOST_RE`) and the phase-A→phase-B implicit interface grew by one (`IP6_FILTER`). See B4. |

---

### Dependency Map

**Build time (host → image).** Structurally unchanged; one edge gained a check. `install.sh:25` `PAYLOAD` (8 items) → `~/.config/claude-devcontainer/` → `cc-isolated.sh --bless` hashes `enforcement_files()` (6 names + 2 globs) → `Dockerfile:389-403` `COPY`s five items. Four independent literals as before. The new bats case installs the **first** edge between two of them (PAYLOAD → enforcement_files), leaving the `Dockerfile` corner unconnected in both directions.

**Ownership invariant — now declared once and asserted once.** New in this range and the cleanest thing in it: `Dockerfile:65-66` narrows node's write grant to `/usr/local/share/npm-global` (declaration), `Dockerfile:419` re-asserts `chown -R root:root /usr/local/share/cc-egress` (belt-and-braces, since `COPY` already lands root-owned), and `init-firewall.sh:302-315` verifies the same property at run time before reading a byte of profile. Build declares, runtime verifies, in that direction. The runtime half is skipped whenever `CC_EGRESS_DIR` is set — see B5.

**Phase A → Phase B.** The implicit interface across the phase banner is now ~18 shell globals plus one function: `ALLOWED_DOMAINS`, `ALLOWED_ENTRIES`, `GH_CIDRS`, `RESOLVED_MEMBERS`, `ANTHROPIC_PROBE_IP`, `DNSMASQ_CONF`, `DNSMASQ_PIDFILE`, `DNSMASQ_UID`, `stop_dnsmasq()`, `SNI_PROXY_BIN`, `SNI_RUN_DIR`, `SNI_ALLOWLIST`, `SNI_PIDFILE`, `SNI_LOG`, `SNI_PORT`, `CCPROXY_UID`, `IP6_FILTER`, plus `GITHUB_DNS_ZONES`/`HOST_RE` reaching `compose_dnsmasq_conf` as globals. `IP6_FILTER` is the newest member and the reason this is worth naming (B4).

**Lock scope — changed shape.** Previously the lock bracketed everything after the trap. It now brackets phase B only: taken at `:540`, after every phase-A read and before `iptables-save` at `:548`. The critical section shrank from "resolution + rebuild" to "rebuild". The cost is a new interleaving (B3).

**Firewall ↔ proxy.** One edge got a name, one edge got wider. The `REJECT sni=… orig_dst=…` grammar is now declared at the producer (`cc-sni-proxy.py:157-161`). The probe simultaneously deepened its dependency: it no longer greps the name alone but `orig_dst=$ANTHROPIC_PROBE_IP:443`, which pulls `original_dst()`'s `"<ip>:<port>"` formatting (`:149-154`) into the contract and makes the log's per-start truncation load-bearing in a new way (B6). The proxy remains a leaf that knows nothing of the firewall — the direction that matters is intact.

**Firewall ↔ resolver ↔ SNI writer (Q3).** The profile-entry grammar is now **one implementation with two consumers** (`HOST_RE`, `:140` and `:221`), which is what r2 asked for. The qualifications: (a) the *data* path is still forked — the ipset loop (`:391`) and the SNI writer (`:977`) consume `ALLOWED_ENTRIES` (parsed), while `compose_dnsmasq_conf` consumes raw `ALLOWED_DOMAINS` and re-derives the domain; (b) the SNI allowlist writer applies **no** grammar check to its `GITHUB_DNS_ZONES` half (`:985-987` emits `.$zone` unvalidated) while the resolver side runs the same zones through `HOST_RE` and warns — so the two consumers of `GITHUB_DNS_ZONES` still disagree about validation even though the two consumers of `HOST_RE` no longer disagree about grammar; (c) `Allowlist.load` **is** still a third parser, but of a *different* grammar (the `name` / `.zone` allowlist-file format, written at `:974-988` and read at `cc-sni-proxy.py:133-142`) that no one has written down anywhere and that validates nothing. Direct answer to the question: the three-parsers-of-one-grammar problem is down to one grammar with two consumers; a *second*, undeclared grammar with one bash writer and one unvalidating Python reader is what remains.

---

### Findings

#### The registry cross-check excludes `claude-home` by asking the filesystem, and the answer differs on a clean checkout

**Severity:** Coupling
**Location:** `test/cc-isolated-functions.bats:496-509`, `.gitignore:38-39`, `devcontainer-config/install.sh:25`, `:37-52`
**Move:** 7 (coupling surface), 8 (extension points)
**Confidence:** High
**Evidence:**
> ```
> @test "every regular file in install.sh's PAYLOAD is hashed by enforcement_files" {
>   # REGRESSION: cc-sni-proxy.py shipped in neither list, then in only one. The two
>   # lists are hand-maintained; this pins them together. Directories (egress,
>   # claude-home) are covered by globs or deliberately excluded (see the comment
>   # above enforcement_files).
>   local payload_line items item
>   payload_line="$(grep -m1 '^PAYLOAD=(' "$CONFIG_SRC/install.sh")"
>   items="${payload_line#PAYLOAD=(}"; items="${items%)}"
>   for item in $items; do
>     [ -d "$CONFIG_SRC/$item" ] && continue
>     run enforcement_files
>     echo "$output" | grep -qx "$item" || { echo "PAYLOAD item not hashed: $item"; return 1; }
>   done
> }
> ```

(`test/cc-isolated-functions.bats:496-509`, the whole case; read with `setup()` `:13-40`, which builds the fixture config dir the `enforcement_files` call resolves against, and with `install.sh:22-25` and `:37-52`, where `claude-home` is *assembled into `$SRC`* by `rm -rf "$STAGE"; mkdir -p "$STAGE"` on every install run.) Against the repo's own statement about that directory:

> ```
> # Staged image payload, regenerated by devcontainer-config/install.sh on every run
> devcontainer-config/claude-home/
> ```

(`.gitignore:38-39` — read with `git ls-files devcontainer-config/claude-home`, which returns zero paths.)

**Legibility-target:** for-author

The test is the right mechanism and it closes the half of A1 that mattered most: add a file to `PAYLOAD` and forget `enforcement_files()`, and the suite goes red. Three things about *how* it decides what to skip.

First, and concretely: `claude-home` is gitignored and exists only after `install.sh` has run on that machine. So `[ -d "$CONFIG_SRC/claude-home" ]` is true here and false on a clean checkout. Extracting `HEAD` into a temp dir and running the case's own loop over it prints `ASSERTED: claude-home` where this working tree prints `SKIP(dir)` — and `enforcement_files()` does not emit `claude-home`, so on a fresh clone or a CI checkout this test fails, for a reason unrelated to whatever change is under review. The cheapest fix a maintainer reaches for when a test fails on checkout is to loosen it, which is how the one mechanism guarding the registry gets weakened by someone who never read A1 or A2.

Second, the skip conflates two different reasons for exclusion. `egress` is skipped because `enforcement_files()` covers it by glob; `claude-home` is skipped because nothing covers it at all. The comment says "covered by globs **or** deliberately excluded" and the code cannot tell the two apart — so the test cannot fail if someone deletes the `egress/*.txt` glob from `enforcement_files()`, and it silently blesses A2's gap as intended behaviour. This is the third place `claude-home`'s exclusion is now encoded (comment at `cc-isolated.sh:47-48`, `questions.md:16`, and now a `-d` test), and it is the weakest of the three: it is not a decision, it is a stat call.

Third, the parse fails **open**. `grep -m1 '^PAYLOAD=('` takes one line. `PAYLOAD` is already 8 items and 118 characters; the ordinary response to a ninth is to wrap it across lines, at which point `items` silently becomes a prefix of the list and every item on the continuation lines goes unchecked — exactly the class of omission this test exists to catch, now invisible again. (A trailing `#` comment on the line fails loudly instead, which is the right direction and happens by accident.)

**Recommendation:** Three one-liners, in this order. (1) Replace `[ -d … ] && continue` with an explicit list — `local NOT_HASHED=(claude-home)` plus a glob-expansion for `egress` — so the exclusion is a named decision that a reader can grep for and B2's eventual close is a one-line deletion. (2) Assert the array is single-line: `[[ "$payload_line" == *')' ]] || { echo "PAYLOAD is no longer one line — this test under-covers"; return 1; }`. (3) Add the missing direction as a second case: parse `^COPY ` sources out of `devcontainer-config/Dockerfile`, strip the trailing `/`, and assert each is in `PAYLOAD` — that is the direction F1 broke on, and it is still uncovered.

---

#### `claude-home` — 104 files, executable at 0555, `COPY`ed from blessed config — is still outside the manifest, and the manifest still says otherwise

**Severity:** Structural
**Trust boundary:** sec-B2 (security r3, "unchanged this range")
**Location:** `devcontainer-config/cc-isolated.sh:44-70`, `:72-83`, `devcontainer-config/Dockerfile:403`, `:415-418`, `docs/working/questions.md:16`
**Move:** 3 (module boundary), 4 (layer violations)
**Confidence:** High
**Evidence:**
> ```
> # Files whose integrity gates a container (re)build. All of them execute host-side
> # or define the boundary. Keep this list in step with install.sh's PAYLOAD: a file
> # that is installed but not hashed is a boundary artefact nobody blessed (the SNI
> # proxy shipped that way once). claude-home/ (the baked skills/hooks payload) is
> # the one PAYLOAD item still outside this list — see docs/working/questions.md.
> ```

(`cc-isolated.sh:44-48`; the comment runs to `:52`, the function to `:70`, and `compute_manifest()` `:72-83` / `check_manifest()` `:93-111` were read with it. Unchanged in this range — `git diff 2839e59..1434fc9 -- devcontainer-config/cc-isolated.sh` is empty.) Against what the image does with that directory:

> ```
>   find /opt/claude-workflows -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod 0555 {} + && \
> ```

(`Dockerfile:418`; the enclosing `RUN` is `:413-425`, read in full with the `COPY claude-home/ /opt/claude-workflows/` at `:403`. `rg --files -uu devcontainer-config/claude-home | wc -l` → 104.)

**Legibility-target:** for-orchestrator-synthesis

Carried forward from r2 unchanged, and it is the answer to this pass's gate question. Nothing in this range touched `cc-isolated.sh`, `docs/decisions/log.md`, or the `questions.md` row; the two new `questions.md` rows are about IPv6 and the `/usr/local/share` chown. So the position is exactly what it was at `2839e59`: the largest set of *executables* baked from the blessed config directory — the hooks and skills that run in every session under decisions 022 and 023 — is the one set `--bless` does not hash, while the comment two lines above the list asserts that everything in it "executes host-side or defines the boundary". A host-side rewrite of `claude-home/hooks/guard-trusted-writes.py` passes `check_manifest()` silently.

What changed is that the exclusion acquired a third encoding (B1) and lost none, so it is now recorded in three places, none of which is a decision. `docs/decisions/log.md:61` (row 42, pre-existing) does mention it — "`claude-home/` remains outside the manifest (directory hashing is a separate change — questions.md)" — but that sentence states the *fact*, not the *cost*, and points back at the open question. r2 asked for either the walk or a row that says what it costs; neither happened.

I want to be fair about *why* it keeps not happening, because it is a genuine design obstacle and naming it is more useful than repeating the recommendation. `compute_manifest()` (`:72-83`) forks one `sha256sum` per emitted name. Six names is free; 110 is 110 forks on every `--bless` **and every `check_manifest()` at launch**, which is the shape that makes "just walk the directory" feel expensive. That is the thing to fix first, and it is small.

**Security implication:** decision 016's defence-in-depth story rests on "every enforcement file is hashed into a manifest a human approves." That invariant is knowingly partial and the code says it is total. Routed to the r3 security review: the exposure is host-side tampering with `/opt/claude-workflows` contents between install and build (the npm-postinstall threat 016 names), not in-container.

**Recommendation:** Take it in two steps and it is cheap. (1) Change `compute_manifest()` to batch — `while read -r f; …; done` → collect names and `(cd "$cfg" && xargs -d '\n' sha256sum)` — which makes the file count irrelevant and is a strict improvement regardless of what follows. (2) Emit `claude-home` from `enforcement_files()` as a sorted walk (`(cd "$cfg" && find claude-home -type f | LC_ALL=C sort)`), and delete the exclusion from all three places it is now written. If the answer is genuinely "not now", then the comment at `:44-48` must stop claiming the list covers everything that defines the boundary, and the deferral belongs in `docs/decisions/log.md` as its own row with the cost stated — not as a clause inside row 42's rationale.

---

#### The lock now brackets phase B only, so a concurrent run fails in phase A and raises the fail-closed alarm

**Severity:** Minor
**Trust boundary:** sec-B6 / sec-S4 (security r3); filed there as **sec-N1**
**Location:** `devcontainer-config/init-firewall.sh:523-545`, `:356-367`, `:268-298`, `devcontainer-config/cc-isolated.sh:416-427`, `devcontainer-config/devcontainer.json:121`
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** High
**Evidence:**
> ```
> # Serialise phase B on a root-owned lock. Phase A (network reads, no rule changes)
> # deliberately runs OUTSIDE the lock: concurrent phase-A runs are harmless, and
> # keeping the critical section to the ~sub-second rebuild means a waiting run is
> # never held for the length of a slow resolution.
> ```

(`init-firewall.sh:527-530`; the enclosing block is `:523-545`, read in full with the `exec 9>` at `:540`, the `chmod 0600` at `:541` and the `flock -w` at `:542`.) Against what phase A does while another run holds the lock:

> ```
> gh_ranges=$(curl -s --connect-timeout 5 --max-time 15 https://api.github.com/meta || true)
> if [ -z "$gh_ranges" ]; then
>     echo "ERROR: Failed to fetch GitHub IP ranges" >&2
>     exit 1
> fi
> ```

(`init-firewall.sh:363-367`; read with the resolution loop `:389-430` and the EXIT trap `:268-298` that any `exit 1` from here lands in.)

**Legibility-target:** for-author

Moving the lock down is the right call for the reason the comment gives, and the fact-check confirmed the placement (after every phase-A read, before `iptables-save`). The claim that needs narrowing is "concurrent phase-A runs are harmless". Two *phase-A* runs are indeed harmless. A phase-A run concurrent with another run's *phase B* is not: run 1 sets `-P OUTPUT DROP` at `:560` and rebuilds for the length of the ipset population, and during that window run 2's `curl https://api.github.com/meta` and its per-domain `dig`s have no egress. Run 2 then takes `exit 1` at `:366` — or the critical-domain exit at `:409` — into the EXIT trap, which forces DROP policies (already DROP, so no harm to the ruleset) and prints `ERROR: init-firewall.sh did not complete.` plus the `recreate it from the host` advice.

The outcome is a false alarm, not a broken boundary: run 1 completes, `FIREWALL_COMPLETE=1`, the container is fine. But the script has exactly three invocation paths (`devcontainer.json:121` `postStartCommand`, `cc-isolated.sh:425`'s re-assert, a manual `sudo`), and `cc-isolated.sh:426` reacts to a non-zero status with `ERROR: init-firewall.sh failed. It fails closed, so this container may now …`. So the concurrency case the lock exists to handle now produces, in the launcher, a message indistinguishable from a genuine failure. Before this range, run 2 simply waited. The trade was deliberate and defensible; the comment should say what was traded away.

**Recommendation:** Either extend the comment at `:527-530` to state the residual ("a run whose phase A overlaps another run's phase B will fail its reads and exit via the trap; the ruleset is unaffected, the message is not"), or — better and still small — take the lock non-blockingly *before* phase A purely to detect the overlap, and on failure wait for it and then re-run phase A rather than entering it blind. The second keeps the short critical section and removes the false alarm.

---

#### The phase boundary is an ~18-variable implicit interface, and there is an unlabelled third region ahead of it

**Severity:** Informational
**Trust boundary:** the hook seam is sec-B3 / sec-S9 (security r3, **sec-N5**)
**Location:** `devcontainer-config/init-firewall.sh:299-334`, `:336-355`, `:432-517`, `:519-521`, `:643`
**Move:** 2 (responsibility boundaries), 5 (interface segregation)
**Confidence:** Medium
**Evidence:**
> ```
> IP6_FILTER=0
> if command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1; then
>     IP6_FILTER=1
> ```

(`init-firewall.sh:509-511`; the enclosing precondition block is `:500-517`, read with its two sibling blocks — dnsmasq `:432-471` and SNI `:473-498` — and with the consumer at `:582`.) Against the region that has no banner at all:

> ```
> trap fail_closed_on_abort EXIT
> trap 'exit 143' INT TERM HUP QUIT
>
> # The profile directory must be root-owned all the way up: …
> ```

(`init-firewall.sh:299-302`; the unlabelled region runs from `:299` to the `PHASE A` banner at `:336` and contains the traps, the ownership assertion `:302-315`, the allowlist composition `:317-321` and the full parse `:322-333`.)

**Legibility-target:** for-orchestrator-synthesis

Direct answer to the shape question. The script's *stated* shape is two phases. Its *actual* shape is now four regions: prologue and pure functions (`:29-235`), an unlabelled "config preconditions" region (`:299-334`: traps, ownership assertion, compose + parse), PHASE A (`:336-517`: network reads, then three capability-probe blocks), PHASE B (`:519-1087`). Each block in this range is in the right *region* — the ownership assertion must follow the traps (so its `exit 1` fails closed) and must precede `compose_domains` (so nothing is read from an unverified tree), and the IPv6 probe now sits with the other two capability probes under an identical banner. Nothing is misplaced. What is missing is the third banner: a reader who has internalised "phase A is where preconditions live" will look for the ownership assertion in phase A and not find it.

Two smaller notes on the same axis. The phase-A banner promises "no network reads past this point" and phase B honours that, but `compose_dns_resolvers` is still called at `:643`, inside the lock and after the flush — a local file read, so compliant, but it is the last input read that was not hoisted alongside the three that were, and its failure mode is the warn-and-continue branch at `:658-685`. And the boundary itself is an implicit interface of ~18 globals (enumerated in the Dependency Map), which is the single thing that would make a `phase-a.sh`/`phase-b.sh` split expensive — not the line count. `IP6_FILTER` is a well-behaved addition to it (assigned unconditionally at `:509`, so no `set -u` trap on the else path), but it is the third precondition block to add one.

**Recommendation:** Add a `# === PRECONDITIONS — ownership, profile parse. Fails closed; no network. ===` banner at `:302` so the file's four regions are all named. No code change. When F6/A8 is eventually taken, the phase-A→phase-B split is the expensive cut and the composition-lib extraction is the cheap one — take the cheap one first.

---

#### `CC_EGRESS_DIR` now switches a boundary assertion off, in a family whose convention is "relocates one artefact"

**Severity:** Coupling
**Trust boundary:** sec-B3 / sec-S9 (security r3); filed there as **sec-N4**
**Location:** `devcontainer-config/init-firewall.sh:302-315`, `:31-38`, `:536-538`, `devcontainer-config/Dockerfile:423`
**Move:** 3 (module boundary), 5 (interface segregation)
**Confidence:** High
**Evidence:**
> ```
> # Asserted on the image default only; CC_EGRESS_DIR is a test override
> # that `node` cannot pass through sudo env_reset.
> if [ -z "${CC_EGRESS_DIR:-}" ]; then
>     for d in "$EGRESS_DIR" "$(dirname "$EGRESS_DIR")"; do
> ```

(`init-firewall.sh:306-309`; the enclosing block is `:302-315`, read with the `EGRESS_DIR` assignment at `:40` and the PATH pin at `:31-38`.) Against the newest member of the same family, which is validated:

> ```
> FIREWALL_LOCK_WAIT="${CC_FIREWALL_LOCK_WAIT:-120}"
> [[ "$FIREWALL_LOCK_WAIT" =~ ^[0-9]+$ ]] || FIREWALL_LOCK_WAIT=120
> ```

(`init-firewall.sh:537-538`; read with `:536` and `:540-545`.)

**Legibility-target:** for-author

r2's A5 said the override family had grown to span two risk classes with one convention. This range added a third behaviour to the same convention without distinguishing it: `CC_EGRESS_DIR` no longer only relocates the profile directory, its *presence* disables a check. The premise that makes this safe is the same one A5 flagged as asserted only in prose — `Dockerfile:423` writes `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh` with no `SETENV` and no `env_keep`, so `node` cannot set it, and I confirmed that line is unchanged. So this is safe today for exactly the reason `CC_FIREWALL_PATH` is safe today, and it inherits `CC_FIREWALL_PATH`'s exposure to any future `Defaults env_keep` — with the difference that an override that turns a check *off* reads, at the call site, like an override that moves a path.

The gate is also testing the wrong proposition. The invariant is "the shipped profile tree is root-owned"; the condition is "no override was passed". Those coincide today. `if [ "$EGRESS_DIR" = "/usr/local/share/cc-egress" ]` tests the actual proposition, costs the same, and does not degrade if someone later sets `CC_EGRESS_DIR` to the default path for an unrelated reason.

Meanwhile `CC_FIREWALL_LOCK_WAIT` picked up a validation line — the only override in the family that has one — so the family now has four shapes for one job: unvalidated relocation (`CC_DNSMASQ_CONF`, `CC_SNI_RUN_DIR`, `CC_FIREWALL_LOCK`), validated scalar (`CC_FIREWALL_LOCK_WAIT`), root-binary selection (`CC_FIREWALL_PATH`), and assertion switch (`CC_EGRESS_DIR`).

**Security implication:** routed to the r3 security review, as A5 was. The question for that review is whether an override whose presence disables a boundary assertion should be reachable at all, or whether both it and `CC_FIREWALL_PATH` should be gated on `[ -n "${BATS_TEST_FILENAME:-}" ]`.

**Recommendation:** Change the guard to compare `$EGRESS_DIR` against the image default rather than testing for the override's absence. Take r2's A5 recommendation at the same time (gate on an explicit test marker; add the bats case that greps the generated sudoers line for the absence of `SETENV`/`env_keep`) — the two are one edit to the same convention.

---

#### The log contract is declared where it is produced, not where it is depended on — and the truncation half is still undeclared, while the probe's reliance on it grew

**Severity:** Coupling
**Location:** `devcontainer-config/cc-sni-proxy.py:157-161`, `:149-154`, `:242-250`, `:303`, `devcontainer-config/init-firewall.sh:1068-1081`
**Move:** 3 (module boundary), 6 (substitutability)
**Confidence:** High
**Evidence:**
> ```
> def log(msg):
>     """One line per decision. CONTRACT: init-firewall.sh's verification probe greps
>     this log for `REJECT sni=<name> orig_dst=<ip>:<port>` — keep that field order and
>     spelling stable, or change the probe in the same commit."""
> ```

(`cc-sni-proxy.py:157-161`; read with `original_dst()` `:149-154`, whose `f"{socket.inet_ntoa(ip)}:{port}"` is the other half of the format the probe now matches, and the three call sites `:183`, `:186`, `:195`, `:197`.) Against the consumer that acquired a second dependency in the same commit:

> ```
> if ! grep -q "REJECT sni=not-allowlisted.invalid orig_dst=$ANTHROPIC_PROBE_IP:443" "$SNI_LOG" 2>/dev/null; then
> ```

(`init-firewall.sh:1078`; the enclosing verification block runs `:1053-1082` and was read in full, with the `-t nat -C` assertion at `:1074` and the `ANTHROPIC_PROBE_IP` guard at `:1056-1059`.)

**Legibility-target:** for-author

The declaration is real and it is good — it names the exact substring, the field order, and the "change both in one commit" obligation. Two gaps remain, and one of them got wider in this range rather than narrower.

It is declared at the producer. r2's point was that the *firewall* is where the dependency is invisible: `init-firewall.sh:1078` still reads as an implementation detail, and a maintainer editing the probe has no local signal that a Python docstring 900 lines away is the other half of it. The new comment at `:1070-1073` explains why `orig_dst` is the discriminator — good reasoning, and the two new bats cases (`FORGED_SNI_LOG`, `NO_REDIRECT`) pin it — but it never says "this grammar is a contract; see `cc-sni-proxy.py:157`."

The truncation half is still declared only in argparse help (`--log … (truncated on start)`, `:303`) and implemented at `:250` (`O_TRUNC`). That is now *more* load-bearing than it was: the probe matches `orig_dst=$ANTHROPIC_PROBE_IP:443`, and `ANTHROPIC_PROBE_IP` is whichever address `dig` returned first this run (`:423-425`). On a CDN with rotating A records a stale line usually will not match — but when the same address comes back, a refusal logged by the *previous* run satisfies today's probe, and the only thing preventing that is `O_TRUNC` in a function whose docstring talks about exit status instead.

**Recommendation:** Two lines. Add the truncation clause to `log()`'s docstring (or to `daemonize()`'s, cross-referenced from `log()`'s): "the log is truncated on each daemon start (`daemonize`, `O_TRUNC`); the probe relies on that to reject a stale refusal from a previous run." And add a one-line pointer at `init-firewall.sh:1078` naming `cc-sni-proxy.py:157` as the contract, so the dependency is legible from both ends.

---

#### The tcp/443 redirect rule is written out twice, 69 lines apart — but unlike this project's other duplications, this one detects itself

**Severity:** Minor
**Trust boundary:** touches sec-N2 (security r3 wants four more `-C` assertions)
**Location:** `devcontainer-config/init-firewall.sh:1005`, `:1074`, `test/init-firewall-rules.bats:779`, `:924`
**Move:** 7 (coupling surface)
**Confidence:** High
**Evidence:**
> ```
> iptables -t nat -A OUTPUT -p tcp --dport 443 -j CC_SNI
> ```

(`init-firewall.sh:1005`, the last line of the nat block `:1000-1005`.) And:
> ```
> if ! iptables -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI; then
>     echo "ERROR: Firewall verification failed - the tcp/443 redirect to the SNI proxy is not installed"
> ```

(`init-firewall.sh:1074-1075`; the enclosing block is `:1068-1081`. `grep -rn 'dport 443 -j CC_SNI' devcontainer-config/ test/` returns four hits: these two plus `test/init-firewall-rules.bats:779` and `:924`, which assert the `-A` and the `-C` respectively.)

**Legibility-target:** for-author

Direct answer to the fourth-copy question: a variable is defensible but low priority, and this duplication is a different species from F1/F4. Those drifted silently — a name in one list and not another produced a wrong boundary that nothing observed. This pair is **self-checking by construction**: the `-C` is a rule-exists query against the rule the `-A` installed, so if either literal is edited without the other, `-C` returns 1, the script exits 1, and the EXIT trap forces DROP. Drift here is loud, immediate, and fails in the safe direction — which is precisely what the new `NO_REDIRECT` bats case at `:922-928` demonstrates. Deduplicating buys legibility, not safety.

The two test copies are the ones that could rot quietly, since a reformatted rule would make `grep -q "^iptables -t nat -C …$"` fail — but as a test failure, which is also loud.

**Recommendation:** Optional, and only if the block is touched for another reason: `SNI_REDIRECT_RULE=(-t nat OUTPUT -p tcp --dport 443 -j CC_SNI)` does not factor cleanly because `-A`/`-C` sit between `-t nat` and the chain; `CC_SNI_MATCH=(-p tcp --dport 443 -j CC_SNI)` does, expanded as `iptables -t nat -A OUTPUT "${CC_SNI_MATCH[@]}"` and `iptables -t nat -C OUTPUT "${CC_SNI_MATCH[@]}"`. Do not spend a commit on it alone.

---

#### The ownership assertion says "all the way up" and checks two levels

**Severity:** Minor
**Trust boundary:** sec-B3a (security r3, marked closed)
**Location:** `devcontainer-config/init-firewall.sh:302-315`
**Move:** 4 (layer violations)
**Confidence:** High
**Evidence:**
> ```
> # The profile directory must be root-owned all the way up: directory WRITE
> # permission on a parent lets its owner rename or unlink a child regardless of the
> # child's own ownership, …
> if [ -z "${CC_EGRESS_DIR:-}" ]; then
>     for d in "$EGRESS_DIR" "$(dirname "$EGRESS_DIR")"; do
>         if [ "$(stat -c '%u' "$d")" != "0" ] || [ -n "$(find "$d" -maxdepth 0 -perm /022)" ]; then
> ```

(`init-firewall.sh:302-310`; the block closes at `:315` and was read with `EGRESS_DIR="${CC_EGRESS_DIR:-/usr/local/share/cc-egress}"` at `:40`.)

**Legibility-target:** for-author

The mechanism is right and the fix it implements — `Dockerfile:65-66` narrowing node's grant from all of `/usr/local/share` to `/usr/local/share/npm-global` — is the correct shape. The assertion walks exactly two levels: `/usr/local/share/cc-egress` and `/usr/local/share`. `/usr/local` and `/` are not checked, and the comment says "all the way up". Both unchecked levels are root-owned `0755` in the image, so nothing is exposed today; the mismatch is between the stated invariant and the code that enforces it, which is the kind of gap that survives a later `chown` somewhere unrelated.

A `while [ "$d" != "/" ]; do … d="$(dirname "$d")"; done` loop is the same number of lines and makes the comment true. It also removes the reader's need to know that `/usr/local` happens to be safe.

**Security implication:** low — the exposure is a hypothetical future `chown` of `/usr/local`. Routed to the r3 security review only to confirm that reading; and to code-fact-check, since "all the way up" vs. two levels is a comment-accuracy claim as much as a structural one. *(route: code-fact-check)*

**Recommendation:** Walk to `/`, or narrow the comment to "the directory and its parent" and say why two levels suffice.

---

### What Looks Good

- **A7 closed better than it was filed, and produced a convention rather than a one-off.** The IPv6 probe did not merely move to phase A; it moved under a banner (`# --- IPv6 preconditions (see the IPv6 block in phase B) ---`, `:500`) identical in form to the dnsmasq (`:432`) and SNI (`:473`) banners, so there are now three instances of one idiom and a fourth precondition block has an obvious template. The decision itself also got sharper: `:512-516` makes "no filter table but a global IPv6 address" fatal *before* the flush, which converts r2's "the script's only warn-and-continue control" from a real gap into a branch that can only fire when there is nothing to filter. *(route: code-fact-check — the loop-pass verified `IP6_FILTER` is assigned unconditionally; the reachability argument for the warning branch is mine and rests on `ip -6 addr show scope global` being a complete test for "has usable IPv6", which is a networking claim, not a structural one.)*

- **The ownership invariant is declared at build and verified at run time, in that direction.** `Dockerfile:65-66` (narrow the grant) → `Dockerfile:419` (re-assert on the profile tree) → `init-firewall.sh:302-315` (verify before reading). The runtime check depends on the build, never the reverse, and the build's comment at `:59-64` states the mechanism — parent-directory write permission defeats child ownership — rather than just the fix. This is also the *existing* image pattern rather than a new one: `ANDROID_HOME` (`:231`), rustup/cargo (`:297`), dotnet (`:352`) all use root-owned tree + narrow carve-out, and the egress artefacts joined it instead of inventing a fourth shape. *(route: code-fact-check for the claim that `COPY` lands root-owned so `:419` is redundant belt-and-braces.)*

- **`HOST_RE` is the right kind of close: one literal, and the shared form got stricter rather than being averaged down.** `:129-130` declares it once; `:140` and `:221` consume it. The previous reconciliation went the permissive way (r2 A4 recorded `)+$` → `)*$`, admitting single labels on both sides to match); this range reversed that to `)+` and gave the reason in the comment — a single-label entry becomes `server=/com/<ns>`, which forwards every `.com` name upstream and re-opens the tunnel the resolver exists to close. `test/init-firewall-rules.bats:853-865` was inverted from asserting the old behaviour to asserting the new. Reconciling two implementations by tightening, with the security argument written down, is the outcome to want.

- **The new negative-probe assertions test the right proposition.** `:1074` asserts the nat rule exists rather than trusting the log, and `:1078` requires the refusal to carry the *redirected* original destination — so a refusal produced by connecting straight to `127.0.0.1:3443` (which `-o lo` permits) no longer satisfies it. The two new bats cases (`FORGED_SNI_LOG`, `NO_REDIRECT`) pin exactly those two failure modes. The pattern — "the observation is not proof unless it could only have been produced through the path under test" — is the same one `:1068-1069` already applied to the curl, applied one level deeper.

- **The `ANTHROPIC_PROBE_IP` guard states a guarantee instead of relying on it.** `:1053-1059` asserts non-empty and says in its comment that the assertion is redundant given `:407-410`, and why it is there anyway. Redundant checks that document their own redundancy are cheap and survive refactors that break the invariant they assume.

- **The `FAIL` log reword (`cc-sni-proxy.py:195`) fixed a diagnostic that pointed at one of two causes.** `(resolved address not in the ipset?)` → `(name unresolvable, or address not admitted by the ipset)`: the same `OSError` arrives from `getaddrinfo` failing against the filtering dnsmasq and from `open_connection` being rejected by the ipset, and after the resolver landed the first is the more likely. Not structural, but it is the operator-facing half of a two-control interaction.

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| B1 | The registry cross-check skips `claude-home` via `-d` on a gitignored, install-generated directory — fails on a clean checkout, conflates "glob-covered" with "excluded", and under-covers silently if `PAYLOAD` is ever wrapped | Coupling | `test/cc-isolated-functions.bats:496-509`, `.gitignore:38-39` | High |
| B2 | `claude-home/` (104 files, `*.sh`/`*.py` at 0555 in `/opt/claude-workflows`) still outside the bless manifest while `enforcement_files()`'s comment asserts full coverage — **the one Structural finding still open** | Structural | `cc-isolated.sh:44-70`, `Dockerfile:403`, `:415-418` | High |
| B3 | Locking phase B only means a run whose phase A overlaps another's phase B fails its network reads and raises the fail-closed alarm through the launcher | Minor | `init-firewall.sh:523-545`, `:363-367`, `cc-isolated.sh:416-427` | High |
| B4 | Four regions, two banners: the traps + ownership assertion + parse sit in an unlabelled region ahead of phase A; the phase boundary is an ~18-global implicit interface, `IP6_FILTER` newest | Informational | `init-firewall.sh:299-334`, `:500-517` | Medium |
| B5 | `CC_EGRESS_DIR`'s presence now disables a boundary assertion — a third behaviour under a convention that reads as "relocates one artefact"; the guard tests for the override, not for the invariant | Coupling | `init-firewall.sh:302-315`, `:31-38` | High |
| B6 | Log contract declared at the producer (`log()`) but not at the consumer; the truncate-on-start half is still undeclared while the probe's reliance on it grew (`orig_dst=$ANTHROPIC_PROBE_IP`) | Coupling | `cc-sni-proxy.py:157-161`, `:250`, `init-firewall.sh:1078` | High |
| B7 | The tcp/443 redirect literal appears twice in the script (and twice in tests) — self-detecting drift, unlike F1/F4; a variable is legibility only | Minor | `init-firewall.sh:1005`, `:1074` | High |
| B8 | Ownership assertion's comment says "root-owned all the way up"; the loop checks two levels | Minor | `init-firewall.sh:302-315` | High |

---

### Overall Assessment

**Yes — one Structural finding remains open: A2, carried forward as B2.** `claude-home/` is `COPY`ed from the blessed config directory, made executable at 0555 across 104 files, runs in every session under decisions 022/023, and is not hashed by `--bless`; the comment above `enforcement_files()` still says the list covers everything that "executes host-side or defines the boundary". Nothing in `2839e59..1434fc9` touched `cc-isolated.sh`, `docs/decisions/log.md`, or the `questions.md` row. It is not a defect in the shipped state — the exposure is host-side tampering between install and build — and it does not block the rebuild, but it is the same Structural finding r2 filed, at the same status, and it now has a third encoding (a `-d` test) that makes it look decided when it is not.

**A1 is the other half of the gate answer, and it moved substantially.** The new bats case is the right mechanism and it closes the direction that matters most — a boundary file added to `PAYLOAD` and forgotten in `enforcement_files()` now turns the suite red. It is not brittle in the way the question anticipated (a trailing comment fails loudly, which is fine); it is brittle in two other ways, one verified and one latent. Verified: `claude-home` is gitignored and assembled by `install.sh`, so the `-d` skip resolves differently on a clean checkout — extracting `HEAD` to a temp dir and running the case's own loop prints `ASSERTED: claude-home`, and `enforcement_files()` does not emit it, so the test fails on a fresh clone for reasons unrelated to the change under review. Latent: `grep -m1 '^PAYLOAD=('` silently under-covers the moment the 8-item array is wrapped across lines. Both are one line each to fix (a named `NOT_HASHED=(claude-home)` list; an assertion that the line ends in `)`), and the third line worth adding is the `Dockerfile COPY ⊆ PAYLOAD` direction, which is the one F1 actually broke on and is still uncovered. With those, A1 closes properly and B2's eventual close becomes a one-line deletion in a place a reader can find.

**On the three specific structural questions the fixes were meant to answer.** Phase structure (Q2): each new block is in the right place — the ownership assertion must follow the traps and precede any profile read, and it does; the IPv6 probe now sits with its two siblings under an identical banner, which turns a placement fix into a convention. What the script does not yet have is the *name* for the region between the trap and the phase-A banner, which now holds two responsibilities; the shape is "preconditions → phase A reads → lock → phase B rebuild → probes → sentinel", and three of those six are labelled. Grammar (Q3): the three-parsers problem is genuinely down to one grammar with two consumers, and the reconciliation went the strict way with the reason recorded — but `Allowlist.load` *is* still a third parser, of a different and entirely undeclared grammar (the `name`/`.zone` allowlist file, bash-written at `:974-988`, Python-read at `:133-142`, validated by neither), and the SNI writer applies no check at all to its `GITHUB_DNS_ZONES` half while the resolver side does. Duplicate literal (Q4): a variable is optional, because unlike every other duplication in this codebase's history this pair checks itself — `-C` queries the rule `-A` installed, so drift exits non-zero into the fail-closed trap. Do not spend a commit on it alone.

**On the split (Q5).** Net neutral-to-slightly-harder, and for a different reason than line count. `HOST_LABEL`/`HOST_RE` are two more globals the composition lib must carry, which is fine — they belong with the four functions and move as one unit. The hook seam is fully intact: all four `--print-*` hooks still exit ahead of the trap, the new ownership assertion, and the lock, so a test invocation still cannot take the lock or touch the boundary. What got harder is the *other* cut: the phase-A→phase-B boundary is now an implicit interface of roughly eighteen shell globals, `IP6_FILTER` being the third precondition block to add one. If the split is ever taken, extract the composition functions (cheap, seam already there) and leave the phase split alone until that interface is declared.

**Recommended order.** B1's three one-liners (they also make B2's close trivial) → B2's `compute_manifest` batching, then the walk or a real decision row → B6's two comment lines (cheapest fix with a real failure mode behind it) → B5 folded into r2's A5 when the override convention is taken → B3's comment or non-blocking pre-check → B4/B7/B8 opportunistically. A6 and the A4 residues stay parked with F5 and F3.

### Goal-Alignment Note
- Answered: yes. The gate question is answered explicitly — **one Structural finding remains open (A2/B2)**, and it is the same one r2 filed, unchanged. A1–A8 each carry a status row with evidence. The five structural questions are answered: (1) the new bats test is the right mechanism but excludes `claude-home` by stat'ing a gitignored build artefact — verified to fail on a clean checkout — covers only one of the two directions r2 asked for, and under-covers silently if `PAYLOAD` is wrapped; A2 is Structural, not an accepted gap, and the concrete recommendation is both (`compute_manifest` batching + the sorted walk) with the decision-log row as the fallback if the walk is declined; (2) the shape is right, each new block is in the right place, and the missing piece is a banner for the unlabelled precondition region — the IPv6 move produced a three-instance convention; (3) the profile grammar is now one implementation with two consumers, but `Allowlist.load` is still a third parser of a *second*, undeclared grammar, and the SNI writer's `GITHUB_DNS_ZONES` path is unvalidated where the resolver's is not; (4) a variable is legibility-only because the `-A`/`-C` pair is self-detecting and fails closed; (5) net slightly harder, and the reason is the ~18-global phase interface, not the +60 lines — the composition-lib seam is untouched.
- Out of scope: whether a logged `REJECT` plus an installed nat rule constitutes sufficient *proof* of the boundary (security's call); IPv6 default-deny and the new abort-on-addressed-without-filter as policy choices; ClientHello parsing; allowlist content; the bats suites' own design beyond the one case handed to me as A1's answer; the `find`/`stat` additions to the script's runtime dependency set. No r3 Trust Boundary Map existed at the time of writing (`ls docs/reviews/*egress*r3*` → no matches), so no finding carries a boundary label.
- Escalate: (1) **B2 is the gate answer** — one Structural finding open, unchanged from r2, and now with a third encoding that makes it look decided; the honest blocker is `compute_manifest()`'s per-name `sha256sum` fork, which is a small fix worth doing first. (2) **B1 is a verified test failure on a clean checkout** — the mechanism that closes A1 is red outside this working tree, and the natural response to that is to loosen it; three one-liners fix it. (3) **B5 has a security dimension the r3 security review should rule on** — `CC_EGRESS_DIR`'s presence now switches off a boundary assertion, which is a new behaviour under A5's still-ungated override convention. (4) **B8 is partly a comment-accuracy claim** ("all the way up" vs. two levels) and is routed to code-fact-check as well as security.
