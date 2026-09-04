# Architecture Review — egress hardening pass 4, 1434fc9..f313de7

Commit: f313de7

**Scope:** `git diff 1434fc9..f313de7 -- devcontainer-config/` — `cc-isolated.sh` (the manifest region: `enforcement_files()` `:45-75`, `compute_manifest()` `:77-93`), `init-firewall.sh` (1087 → 1116; the ownership assertion, the relocated lock block, the five-rule `-C` loop, the trimmed post-probe block), `Dockerfile` (the sudoers hardening hunk), `cc-sni-proxy.py` (`READY_TIMEOUT` + the bounded `select` in `daemonize`), `egress/base.txt` (one comment sentence) — plus the two registry cases in `test/cc-isolated-functions.bats:496-539`, read as the answer to r3's B1/B2 rather than as tests under review. Read as committed context but not themselves reviewed: `test/init-firewall-rules.bats` (+51/−6, the lock/`-C`/owner-check cases), `docs/working/questions.md`, `docs/reviews/*-r3.md`.
**Date:** 2026-09-03
**Based on:** `docs/reviews/architecture-review-2026-09-03-egress-hardening-r3.md` (on `1434fc9`, findings B1–B8) and the pass-4 code-fact-check (k=1 on `563448a`: 0 Incorrect, 5 Mostly accurate, all comment prose, all corrected in `f313de7`). My labels this pass are `C1`–`C7`.

**Trust-boundary cross-reference:** `docs/reviews/security-review-2026-09-03-egress-hardening-r4.md` does not exist (`ls docs/reviews/ | grep r4` → no matches at the time of writing), so no finding below carries an r4 boundary label. Where a boundary is named I use the r3 security labels (**sec-B<n>**, **sec-N<n>**) as r3 did, and flag which ones the r4 security pass should re-rule on.

---

### Prior findings status

| Prior # | Finding (r3) | Status | Evidence |
|---|---|---|---|
| B1 | Registry cross-check skipped `claude-home` by `-d` on a gitignored build artefact; conflated "glob-covered" with "excluded"; parsed `PAYLOAD` fail-open; only one of two directions | **closed, with two Minor residues (C7)** | All three one-liners taken. The skip is now a named list (`case "$item" in egress|claude-home) continue`, `:507-509`), so it no longer stats the filesystem and no longer differs on a clean checkout. The single-line assertion is in (`[[ "$payload_line" == *")" ]] || { echo "PAYLOAD spans lines; update this test"; return 1; }`, `:504`). The missing direction is in (`{Dockerfile COPY sources} ⊆ PAYLOAD`, `:516-520`). `run enforcement_files` also moved out of the loop. Residues: the `COPY` parse is `awk '{print $2}'` (breaks on `--chown=`/`--from=`, loudly), and the skip list's *reason* changed under it without the code being able to tell — see C7. |
| B2 | `claude-home/` (104 files, 0555 scripts) outside the bless manifest while the comment asserted full coverage — **the one Structural finding open at r3** | **CLOSED as Structural; one Coupling residue (C1)** | `enforcement_files()` `:71` now emits `if [ -d claude-home ]; then find claude-home -type f \| LC_ALL=C sort; fi`, and `compute_manifest()` `:78-93` collects into `files[]` and forks **one** `sha256sum` — r3's recommended order (batch first, then walk) taken in exactly that order. `find … -type f \| wc -l` on the staged payload → 104, so all 104 are now hashed, `.manifest` included. The comment `:45-55` no longer claims an exclusion. A second bats case (`:527-539`) proves an edit under `claude-home/` trips `check_manifest`. Residue: `-type f` is not `! -type d` — see C1. |
| B3 | Lock bracketed phase B only, so a run whose phase A overlapped another's phase B failed its reads and raised the fail-closed alarm through the launcher | **closed; new Minor on the cost side (C4)** | The block moved to `:336-370`, ahead of the `PHASE A` banner at `:372` and held to exit; the comment states both interleavings it now closes and the ~270 s hold model behind the 600 s wait. `CC_FIREWALL_LOCK_WAIT` also went from silent-fallback-to-120 to a hard error on a non-integer (`:359-362`). The false-alarm path r3 described is gone. What the change buys, it pays for in wait visibility — C4. |
| B4 | Four regions, two banners; the phase boundary is an ~18-global implicit interface | **open, and the unlabelled region grew** | No `PRECONDITIONS` banner was added. The region between `trap fail_closed_on_abort EXIT` (`:299`) and the `PHASE A` banner (`:372`) now holds traps, the ownership assertion, `compose_domains`, the entry parse **and the lock** — one more responsibility than at r3, and the one with the longest comment in the file. See C6. |
| B5 | `CC_EGRESS_DIR`'s *presence* disabled a boundary assertion; the guard tested for the override, not the invariant | **closed as filed** | `:311` is now `if [ "$EGRESS_DIR" = "/usr/local/share/cc-egress" ] \|\| [ -n "${CC_EGRESS_OWNER_CHECK:-}" ]`, i.e. the invariant plus an explicit, separately-named test knob — which is strictly better than r3's recommendation, because the knob that *enables* the check can no longer be confused with the knob that *relocates* the directory. `test/init-firewall-rules.bats:987-989` exercises it. r2's A5 half (a bats assertion on the generated sudoers line) is answered from the other end: `Dockerfile:429` now emits `Defaults:node env_reset, !setenv` and a bare-invocation grant, so the premise every `CC_*` override rests on is stated in the artefact rather than in prose. |
| B6 | Log contract declared at the producer only; the truncate-on-start half undeclared while the probe's reliance on it grew | **open, unchanged** | `cc-sni-proxy.py` changed in this range only by `import select`, `READY_TIMEOUT = 30.0`, and the bounded parent wait in `daemonize` (`:258-266`). `log()`'s docstring is byte-for-byte as at r3; `O_TRUNC` is still declared only in `--log`'s argparse help; `init-firewall.sh:1107` still greps the grammar with no pointer back. Carried as C5. |
| B7 | The tcp/443 redirect literal written twice, self-detecting | **superseded — the count went from 2 to 5 pairs (C3)** | The `-C` loop at `:1039-1053` adds four more assertions, exactly as sec-N2 asked. Each is a second copy of an install-site literal, and `test/init-firewall-rules.bats:926,980-983` greps all five a third time. r3 said "a variable is optional"; at five triples it is no longer. See C3. |
| B8 | "root-owned all the way up" vs. a two-level loop | **closed** | `:301-310` now says "The profile directory AND its parent must be root-owned…", with "(`/usr/local` and `/usr` are root by construction of the base image and are not re-checked.)" — r3's second option, taken with the reason stated. |

---

### Dependency Map

**Build time (host → image) — the registry is now a closed triangle, mechanically.** `install.sh:25` `PAYLOAD` (8 items) → `~/.config/claude-devcontainer/` → `cc-isolated.sh --bless` over `enforcement_files()` (6 names + 2 globs + 1 walk) → `Dockerfile:389-403` `COPY`s five items. At r3 exactly one of the six directed edges between these three literals was checked. Now two are: `PAYLOAD ∖ {egress, claude-home} ⊆ enforcement_files()` (`:510-514`) and `{COPY sources} ⊆ PAYLOAD` (`:516-520`). The two remaining edges are covered by *construction* rather than by assertion — `egress` by the `egress/*.txt` glob (which is exactly the readable surface: `compose_domains` `:64` only ever opens `$EGRESS_DIR/$p.txt`, so a non-`.txt` file in that directory is inert and its absence from the manifest costs nothing), and `claude-home` by the walk. The walk's coverage is complete for regular files and empty for everything else (C1).

**Manifest coverage — one function, two exclusion philosophies.** `enforcement_files()` now mixes an extension-narrowed glob (`egress/*.txt`) with an unrestricted-by-name but type-restricted walk (`find claude-home -type f`). Both are correct for their own subtree and for different reasons, and neither reason is written down next to the other. The glob is narrow because the consumer is narrow; the walk is wide because the consumer (`COPY claude-home/`) is wide — but `-type f` re-narrows it in a dimension the consumer does not share (C1).

**Provenance is now inside the blessed set.** `install.sh:55-59` writes `claude-home/.manifest` (`commit=`, `dirty=`, `assembled_from=`), the walk hashes it, and `install.sh:109` re-blesses at the end of every install. So the stamp is a *pure function of* (`HEAD`, tree-dirtiness, `REPO_ROOT`) rather than of wall-clock time or run count: re-running `install.sh` at the same commit and the same dirtiness produces a byte-identical `.manifest` and therefore an identical manifest line. This is the answer to Q1 and it is a genuinely sound boundary definition — see the Overall Assessment for the decision-log wording.

**Lock scope — now the whole run, in the script.** `:336-370`, ahead of phase A, released implicitly at exit. All three invocation paths (`devcontainer.json:121` `postStartCommand`, `cc-isolated.sh:432`'s re-assert, a manual `sudo`) go through the same baked script, so there is exactly one lock acquisition per invocation and no nesting anywhere. Both daemon starts still close fd 9 (`:798`, `:1007`); the probes (`runuser -u node -- curl`) inherit it but are short-lived and cannot outlive the script.

**Rule installation ↔ rule verification — a new edge, presence-only.** `:1039-1053` queries five rules that `:816-817`, `:850`, `:1018` and `:1028` installed. Two of the five were installed with `-I OUTPUT 1` and one is a filter jump whose placement relative to `-A OUTPUT -o lo -j ACCEPT` is load-bearing; `-C` cannot see either property (C2).

**Firewall ↔ proxy.** Unchanged in shape. `daemonize`'s new bounded wait (`cc-sni-proxy.py:258-266`) is a good citizen of the new lock scope — it is the one place a child could have parked the lock indefinitely, and the comment says so — but the log-grammar contract still points one way only (C5).

---

### Findings

#### The manifest walk blesses regular files only, and the payload contains one non-regular entry today

**Severity:** Coupling
**Trust boundary:** sec-B2 (security r3: host-side config dir → `check_manifest()` → image build). Re-rule requested from the r4 security pass.
**Location:** `devcontainer-config/cc-isolated.sh:71`, `:77-93`, `devcontainer-config/install.sh:42-52`, `devcontainer-config/Dockerfile:403`, `:420`
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** High
**Evidence:**
> ```
>     if [ -d claude-home ]; then find claude-home -type f | LC_ALL=C sort; fi
> ```

(`cc-isolated.sh:71`, the last line of the subshell `:66-74`; read with the whole of `enforcement_files()` `:56-75`, `compute_manifest()` `:77-93` and `check_manifest()` `:103-121`.) Against what is actually staged into the build context:

> ```
> $ LC_ALL=C find devcontainer-config/claude-home -type f | wc -l
> 104
> $ LC_ALL=C find devcontainer-config/claude-home ! -type d | wc -l
> 105
> $ LC_ALL=C find devcontainer-config/claude-home -type l
> devcontainer-config/claude-home/workflows/workflows
> $ LC_ALL=C ls -l workflows/workflows
> lrwxrwxrwx … workflows/workflows -> /home/magfrump/claude-workflows/workflows
> ```

(run in this working tree at `f313de7`; the staging loop that produces it is `install.sh:42-52`, `cp -r` over `CLAUDE_HOME_SRC=(CLAUDE.md skills workflows guides patterns hooks scripts)`, and `git ls-files -s workflows` confirms mode `120000` for that path in the repo.)

**Legibility-target:** for-orchestrator-synthesis

This is B2's residue, and it is the reason I am recording B2 as closed-at-Structural rather than closed outright. The walk covers 104 of the 105 non-directory entries the payload actually contains. The 105th is a symlink that `cp -r` preserves, that `install.sh:98-101` copies into the installed config, that `COPY claude-home/ /opt/claude-workflows/` puts into the image, that `chown -R root:root` at `:420` touches (without dereferencing) — and that `find … -type f` does not emit, so `--bless` never records it and `check_manifest` cannot see it appear, disappear, or be repointed.

Two things keep this Coupling rather than Structural, and both are worth stating because they are the reasons a future change could move it back up:

1. **Deletion and replacement are still caught.** If a host-side attacker replaces a hashed regular file with a symlink, that file's line vanishes from `compute_manifest`'s output and the manifest text differs — `check_manifest` fails. The gap is one-directional: only *additions* of non-regular entries are invisible.
2. **An added symlink cannot smuggle content into the image.** Its target must exist in the image to be readable, and everything in the image at a path an added link could usefully name is either root-owned-0444/0555 payload or absent. The concrete instance is dangling: `/home/magfrump/claude-workflows/workflows` does not exist in the container. So today's exposure is "an unblessed artefact rode into the boundary", not "unblessed code executes" — which is precisely the class decision 016's manifest exists to make impossible, one notch below the class B2 named.

The structural point is smaller than either: `enforcement_files()` now contains two exclusion philosophies and states neither. `egress/*.txt` is narrow because its consumer is narrow (`compose_domains:64` opens only `$EGRESS_DIR/$p.txt`), which makes it exactly right. `find claude-home -type f` is wide by name and narrow by type, while its consumer — `COPY claude-home/` — is wide in both. A reader of `:71` has no way to know whether `-type f` is a decision or a default, and the comment at `:45-55` now reads as a completeness claim ("hashed file by file via a sorted walk").

**Security implication:** routed to the r4 security review under sec-B2. The question for that pass is whether an *added* non-regular entry inside the blessed payload is in scope for the npm-postinstall threat 016 names, given that it cannot carry content. My read is that it is a defence-in-depth gap worth one character to close, not an exposure.

**Recommendation:** One character and one line. Change `-type f` to `! -type d` so the walk emits everything that is not a directory, and add a `-type l`-aware branch to `compute_manifest`'s existence check — or, if hashing link *targets* is unwanted (it is: the target is outside the blessed tree), keep `-type f` and add an assertion instead: `find claude-home ! -type d ! -type f -print -quit | grep -q . && { echo "ERROR: non-regular file in claude-home — not hashable"; return 1; }`. The second is the better shape, because it turns "the walk is complete" from a claim into a checked precondition, and because the symlink that exists today (`workflows/workflows`, an absolute path into the maintainer's host home) is arguably staging noise that should be excluded at `install.sh:46-52` rather than blessed. Whichever is chosen, say in the comment at `:45-55` which classes the walk covers.

---

#### The five new `-C` assertions verify presence; for three of them the load-bearing property is position

**Severity:** Coupling
**Trust boundary:** sec-N2 (security r3 asked for these four extra assertions). Re-rule requested from the r4 security pass.
**Location:** `devcontainer-config/init-firewall.sh:1039-1053`, `:763-768`, `:816-817`, `:846-852`, `:850`
**Move:** 1 (single responsibility), 7 (coupling surface)
**Confidence:** High
**Evidence:**
> ```
> # Every rule the boundary depends on must actually be present — not just the one
> # the SNI probe needs. `-C` queries what `-A`/`-I` installed; drift between the
> # two literals is self-detecting (the run aborts into DROP).
> for rule in \
>     "-t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI" \
>     "-t nat -C OUTPUT -p udp --dport 53 -j CC_DNS" \
>     "-t nat -C OUTPUT -p tcp --dport 53 -j CC_DNS" \
>     "-C OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD" \
>     "-C OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD"; do
> ```

(`init-firewall.sh:1035-1047`; the loop body `:1048-1053` was read with it, including the `IFS=' ' read -r -a rule_args <<< "$rule"` split — a prefix assignment to a regular builtin, so `IFS` is restored afterwards and the script-wide `IFS=$'\n\t'` at `:30` is unaffected.) Against what the install sites say about themselves:

> ```
> # ORDER OF OPERATIONS. The nat rules are INSERTED at position 1, ahead of the
> # `-d 127.0.0.11 -j DOCKER_OUTPUT` jump restored above: were they appended, a
> # node query to 127.0.0.11:53 would be DNAT'd to the embedded resolver before the
> # redirect could claim it.
> ```

(`init-firewall.sh:763-766`, the block comment above the resolver install; the rules themselves are `:816-817` `iptables -t nat -I OUTPUT 1 -p {tcp,udp} --dport 53 -j CC_DNS`, and the filter-side sibling is `:846-850`, whose own comment reads "FILTERING RESOLVER: these must precede the loopback accept (see that block)" immediately above `iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD` and three lines above `iptables -A OUTPUT -o lo -j ACCEPT`.)

**Legibility-target:** for-author

This is the best change in the range and it has one seam. Adding the four assertions closes sec-N2 and makes the verification block say what it means — every rule, not just the one the probe happens to exercise. But `iptables -C` is a membership query, not a position query, and for three of the five rules the script's own comments say in capitals that position is the invariant:

- `-t nat -C OUTPUT -p udp --dport 53 -j CC_DNS` passes whether the rule is at nat OUTPUT position 1 or position 9. At position 9, behind the restored `-d 127.0.0.11 -j DOCKER_OUTPUT` jump, the redirect never claims the flow and the filtering resolver is bypassed for exactly the traffic it exists to filter — while this assertion reports success.
- Same for the tcp twin.
- `-C OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD` passes whether the jump precedes or follows `-A OUTPUT -o lo -j ACCEPT`. Behind the loopback accept it is dead, and the tunnel the whole filtering-resolver block was written to close (`:752-758`, queries straight to `127.0.0.11:<random port>`) reopens silently.

The two `-A`-installed 443 rules are genuinely presence-only properties, so for those the assertion is exactly right.

I want to be fair about the size of this: the rules are installed unconditionally, in one straight-line block, with no `|| true`, so nothing *today* can produce presence-without-position. The gap is between what the verification block now claims ("every rule the boundary depends on must actually be present") and the property that would actually catch the failure the ordering comment describes. It is the same species as B8 — a stated invariant enforced one notch weaker than stated — but on a control rather than a comment, and it appeared in the same commit that made the block authoritative.

**Recommendation:** Cheapest sufficient version, two lines, no new literals: after the loop, assert the two nat redirects are at the top by parsing what is already being read — `iptables -t nat -S OUTPUT | head -2 | grep -qc 'dport 53 -j CC_DNS'` (expect 2), and assert the guard precedes the loopback accept with `iptables -S OUTPUT | grep -n -e '-d 127.0.0.11 -j CC_DNS_GUARD' -e '-o lo -j ACCEPT'` and compare line numbers. If that reads as too clever for this file, the honest alternative is to narrow the loop's comment to "present — position is guaranteed by construction of the single install block above, not by this check" and cross-reference `:763`. Do not leave the current comment as-is: it is the one that will be believed.

---

#### Five rule literals now exist three times each; the shared match array stopped being optional

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:816-817`, `:850`, `:1018`, `:1028`, `:1039-1047`, `test/init-firewall-rules.bats:926`, `:980-983`
**Move:** 7 (coupling surface)
**Confidence:** High
**Evidence:**
> ```
> iptables -t nat -I OUTPUT 1 -p tcp --dport 53 -j CC_DNS
> iptables -t nat -I OUTPUT 1 -p udp --dport 53 -j CC_DNS
> ```

(`init-firewall.sh:816-817`.) Against the assertion copies and the test copies:
> ```
>     "-t nat -C OUTPUT -p udp --dport 53 -j CC_DNS" \
>     "-t nat -C OUTPUT -p tcp --dport 53 -j CC_DNS" \
> ```
> ```
>   grep -q "^iptables -t nat -C OUTPUT -p udp --dport 53 -j CC_DNS$" "$CMD_LOG"
>   grep -q "^iptables -t nat -C OUTPUT -p tcp --dport 53 -j CC_DNS$" "$CMD_LOG"
> ```

(`init-firewall.sh:1044-1045` and `test/init-firewall-rules.bats:980-981`; the same triple exists for `CC_DNS_GUARD` (`:850` / `:1046` / bats `:982`), `CC_SNI_GUARD` (`:1028` / `:1047` / bats `:983`) and `CC_SNI` (`:1018` / `:1043` / bats `:926`).)

**Legibility-target:** for-author

Direct answer to Q4, and the answer changed from r3. At r3 there was one pair and it was self-detecting, so I said a variable buys legibility, not safety, and told you not to spend a commit on it. There are now five pairs plus five test-side literals, and two things follow that did not before.

First, the arithmetic. Fifteen occurrences of five rules is the point at which a reader can no longer confirm agreement by eye, and the self-detection argument — still true for the script's two copies — does **not** extend to the bats copies, which fail as test failures on a *reformat* of a rule that is otherwise correct. That is the rot direction r3 flagged as "loud", and it is now five times as likely.

Second, and the reason this is now actionable rather than aesthetic: **it factors cleanly, and the factoring is the fix for C2's readability half.** The obstacle r3 identified (`-A`/`-C` sit between `-t nat` and the chain) dissolves if the array holds only the match, which is what the five rules genuinely share:

```
CC_DNS_MATCH_TCP=(-p tcp --dport 53 -j CC_DNS)
iptables -t nat -I OUTPUT 1 "${CC_DNS_MATCH_TCP[@]}"     # position 1 is the invariant — see :763
iptables -t nat -C OUTPUT    "${CC_DNS_MATCH_TCP[@]}"
```

The install site keeps `-I OUTPUT 1`, the assertion keeps `-C OUTPUT`, and the difference between them — which is exactly the property C2 says is unverified — becomes visually obvious at both sites instead of buried in two 50-character strings 220 lines apart. The `IFS=' ' read -r -a` split at `:1049` also disappears, and with it the one place in this file where a fixed string is re-parsed at runtime.

**Recommendation:** Declare the five match arrays next to their install sites (not in a block at the top — locality is the point), expand them at both the install and the `-C` site, and drive the loop over the array names. Update the five bats greps in the same commit. This is a mechanical change with a green suite on either side and it is worth a commit now, unlike at r3.

---

#### The lock is in the right layer, but the wait it now implies is up to 600 s and completely silent

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:336-370`, `devcontainer-config/cc-isolated.sh:420-437`, `devcontainer-config/devcontainer.json:121`
**Move:** 2 (responsibility boundaries), 6 (substitutability)
**Confidence:** High
**Evidence:**
> ```
> FIREWALL_LOCK_WAIT="${CC_FIREWALL_LOCK_WAIT:-600}"
> if [[ ! "$FIREWALL_LOCK_WAIT" =~ ^[0-9]+$ ]]; then
>     echo "ERROR: CC_FIREWALL_LOCK_WAIT must be a non-negative integer (got '$FIREWALL_LOCK_WAIT')" >&2
>     exit 1
> fi
> mkdir -p "$(dirname "$FIREWALL_LOCK")" && chmod 0700 "$(dirname "$FIREWALL_LOCK")"
> exec 9>"$FIREWALL_LOCK"
> chmod 0600 "$FIREWALL_LOCK"
> if ! flock -w "$FIREWALL_LOCK_WAIT" 9; then
> ```

(`init-firewall.sh:357-366`; the whole block is `:336-370`, read with its 20-line comment and with the release note at `:1109-1111`.) Against the only caller that a human watches:

> ```
>     echo "Re-asserting firewall via baked init-firewall.sh, then re-probing …"
> ```

(`cc-isolated.sh:423`; the `devcontainer exec … sudo /usr/local/bin/init-firewall.sh` it precedes is `:432`, and the error branch `:433-437`.)

**Legibility-target:** for-author

Direct answer to Q3, in three parts.

**Layer: right, and there is no double-locking.** The lock belongs in the script because the script is the only thing that mutates the boundary, and because two of its three invocation paths (`postStartCommand`, a manual `sudo`) never go through the launcher at all — a launcher-side lock would protect one path in three. Each invocation is a fresh process taking the lock exactly once; nothing nests, and there is no path where the launcher holds a lock while the script tries to take it.

**Ordering between `postStartCommand` and the re-assert: no hazard, by construction.** `devcontainer up` awaits `postStartCommand` before returning, and `cc-isolated.sh:432`'s re-assert only runs after `devcontainer up` returned *and* `probe_boundary` failed. The two are strictly sequential within one `cc-isolated` run. The re-assert exists precisely because `up` on an already-running container *skips* `postStartCommand` — i.e. the case where run 1 never happens. So the residual overlap is two concurrent `cc-isolated` invocations against the same project (same `--id-label`, same container), or a manual `sudo` racing either.

**The cost that moved.** At r3 a waiting run waited out a sub-second rebuild. It now waits out an entire run — the comment's own model is ~270 s at today's allowlist — and `flock -w` prints nothing while it waits. So the concurrency case now surfaces as `cc-isolated` sitting on `Re-asserting firewall via baked init-firewall.sh, then re-probing …` for minutes with no output, which is indistinguishable from a hang, and the natural operator response to a hang is Ctrl-C — which lands on `trap 'exit 143'`, `fail_closed_on_abort`, and a container left at DROP. That is a worse outcome than r3's false alarm, arrived at from the opposite direction. The trade is still correct; it is the silence that is new.

**Recommendation:** Three lines, no design change. Try the lock non-blockingly first, and say so before blocking:

```
if ! flock -n 9; then
    echo "Another init-firewall.sh run is in progress; waiting up to ${FIREWALL_LOCK_WAIT}s …"
    flock -w "$FIREWALL_LOCK_WAIT" 9 || { echo "ERROR: could not take $FIREWALL_LOCK within ${FIREWALL_LOCK_WAIT}s …" >&2; exit 1; }
fi
```

This is the same shape r3 recommended for a different reason and it costs nothing in the uncontended case. Worth adding to the comment at `:336-355` that the hold now includes the probes *and* the two daemon starts, so "a hold longer than the wait is a stuck run" is the operator's diagnostic.

---

#### The log-grammar contract is still declared only at the producer, and truncation is still undeclared

**Severity:** Coupling
**Location:** `devcontainer-config/cc-sni-proxy.py:157-161`, `:250`, `:303`, `devcontainer-config/init-firewall.sh:1107`
**Move:** 3 (module boundary), 6 (substitutability)
**Confidence:** High
**Evidence:**
> ```
> if ! grep -q "REJECT sni=not-allowlisted.invalid orig_dst=$ANTHROPIC_PROBE_IP:443" "$SNI_LOG" 2>/dev/null; then
> ```

(`init-firewall.sh:1107`; the enclosing verification block `:1094-1111` was read in full, including the three comment lines above it that now say the nat rule "was asserted above" — a correct pointer to the `-C` loop, and the only cross-reference the block gained.) Against the range's only change to the producer:

> ```
> +READY_TIMEOUT = 30.0          # daemonize(): how long the parent waits for the child to bind
> ```

(`cc-sni-proxy.py:49`, with the bounded `select` at `:258-266`; `git diff 1434fc9..f313de7 -- devcontainer-config/cc-sni-proxy.py` touches nothing else, so `log()`'s docstring `:157-161` and `daemonize`'s `O_TRUNC` `:250` are byte-for-byte as reviewed at r3.)

**Legibility-target:** for-author

B6 carried forward unchanged; recorded so the r4 gate answer is complete rather than because anything got worse. r3's argument stands verbatim: the grammar is declared where it is produced and consumed where nothing names it as a contract, and the truncate-on-start half — which is what stops a *previous* run's `REJECT` line from satisfying today's probe when the CDN hands back the same address — is documented only in argparse help. Two comment lines, cheapest fix in the backlog, real failure mode behind it.

One thing this range did add on the same edge, and it is a good one: `daemonize`'s bounded wait is the right response to the lock change. Under the old scope a child that hung before signalling readiness blocked a script that held no lock; under the new scope it would have parked the firewall lock for the full 600 s. The comment at `:258-259` names exactly that reason. That is the pattern to want — a change in one module's lifetime assumption tracked into the module that depends on it, with the dependency written down.

**Recommendation:** Unchanged from r3. Add the truncation clause to `log()`'s docstring (or `daemonize()`'s, cross-referenced), and a one-line pointer at `init-firewall.sh:1107` naming `cc-sni-proxy.py:157` as the contract.

---

#### The unlabelled region ahead of phase A now holds five responsibilities, including the lock

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:299-370`, `:372`, `:1109-1111`
**Move:** 2 (responsibility boundaries), 5 (interface segregation)
**Confidence:** Medium
**Evidence:**
> ```
> trap fail_closed_on_abort EXIT
> trap 'exit 143' INT TERM HUP QUIT
>
> # The profile directory AND its parent must be root-owned and not group/world-
> ```

(`init-firewall.sh:298-301`; the region runs to the `PHASE A` banner at `:372` and now contains, in order: the two traps `:299-300`, the ownership assertion `:301-317`, `compose_domains` `:319-323`, the entry parse `:324-335`, and the lock `:336-370`.)

**Legibility-target:** for-orchestrator-synthesis

B4 carried, one responsibility heavier. The script's stated shape is still two phases; its actual shape is now five regions — prologue and pure functions, an unnamed preconditions-and-serialisation region, PHASE A, PHASE B, and the verification-and-sentinel tail — of which two are named. The lock's placement inside the unnamed region is *correct*: it must follow the traps (so a lock failure ends at DROP), and it should follow the cheap parse (so a malformed profile fails fast without making a concurrent run wait). But it is now the longest block in the file's least legible region, and the region's name would tell a reader why an ownership check and a `flock` are neighbours.

The phase-A→phase-B implicit interface is unchanged at ~18 globals; nothing in this range added to it. So the split's expensive cut did not get worse this pass.

**Recommendation:** Unchanged from r3, one line: a `# === PRECONDITIONS AND SERIALISATION — ownership, profile parse, lock. Fails closed; no network. ===` banner at `:301`. No code change.

---

#### Two residues in the registry test, and one 136-character comment line

**Severity:** Minor
**Location:** `test/cc-isolated-functions.bats:504`, `:507-509`, `:516-520`, `devcontainer-config/cc-isolated.sh:51`
**Move:** 7 (coupling surface), 8 (extension points)
**Confidence:** High
**Evidence:**
> ```
>   done < <(grep -E '^COPY ' "$CONFIG_SRC/Dockerfile" | awk '{print $2}')
> ```

(`test/cc-isolated-functions.bats:520`, the last line of the new COPY-direction loop `:516-520`; read with the skip list `:507-509` and the single-line assertion `:504`.) And:
> ```
> # .manifest install.sh writes, so re-running install.sh re-blesses by design. Paths are relative to config_dir. The per-project .profile
> ```

(`cc-isolated.sh:51`, 136 characters, in a comment block whose other lines are 75–85.)

**Legibility-target:** for-author

Three small things, none of which changes a conclusion.

**The `COPY` parse is flag-fragile.** `awk '{print $2}'` yields the source only for the bare `COPY src dst` form. `COPY --chown=root:root claude-home/ /opt/...` — a plausible future edit, given `Dockerfile:418-420` currently does the same job in a separate `RUN` — yields `--chown=root:root`, which is not in `PAYLOAD`, so the test fails. Loudly and in the safe direction, which is why this is Minor rather than a repeat of B1's fail-open; but the failure message ("Dockerfile COPYs --chown=root:root but PAYLOAD lacks it") points at the wrong thing. `awk '{for(i=2;i<=NF;i++) if ($i !~ /^--/) {print $i; break}}'` fixes it in place.

**The skip list's reason drifted out from under it.** `case "$item" in egress|claude-home) continue` is now correct for two *different* reasons — `egress` because the glob covers it, `claude-home` because the walk does — and the inline comment says both ("covered by the glob / sorted walk below"). That is honest and it is a real improvement on r3's `-d` stat. What it still cannot do is fail if either mechanism is deleted from `enforcement_files()`: remove the walk and this test stays green, with the second case (`:527-539`) as the only thing standing between that and a silent regression to B2. Since that second case builds its own fixture rather than reading the real `enforcement_files()` output for `claude-home`, one assertion is missing: that `enforcement_files` emits *something* under each skipped prefix. `echo "$output" | grep -q "^$item/" || { echo "$item excluded but nothing under it is hashed"; return 1; }` inside the `case` closes it in one line and makes the skip list self-defending.

**The comment rewrap.** `cc-isolated.sh:51` runs to 136 characters because "Paths are relative to config_dir." was left appended to the new sentence rather than re-wrapped. The pass-4 fact-check flagged this block's prose and the prose is now accurate; only the wrapping is off.

**Recommendation:** All three are one-liners; take them with whatever touches these files next. The `grep "^$item/"` assertion is the one with actual value — it is what makes B2's close hold under a future edit.

---

### What Looks Good

- **B2 was closed in the order r3 recommended, and the cheap half was done first.** `compute_manifest()` batches into one `sha256sum` before the walk widened the input, so the file count became irrelevant *before* it grew from 6 to 110. The comment at `:81-82` states the reason ("a fork per file made every launch pay for it") rather than just the change. This is the recommendation-shaped-as-two-steps being taken as two steps, which is rarer than it should be, and it means `check_manifest()` at every launch got cheaper in the same commit that made it cover 17× more files. *(route: code-fact-check — the "~100 files" in the comment is 104 today; the claim is a rounded order-of-magnitude, not a count, and the fact-check's k=1 pass already read this block.)*

- **`.manifest` inside the blessed set is the right call, not a churn source, and the reason is structural.** `install.sh:55-59` derives the stamp from `HEAD`, tree-dirtiness and `REPO_ROOT` — all inputs, none of them wall-clock — and `install.sh:109` re-blesses at the end of every install. So the stamp changes exactly when the provenance of the payload changes, which is exactly when a human should be re-approving it, and re-running `install.sh` at an unchanged commit produces a byte-identical manifest. `link-claude-home.sh:69-71` then copies it into the volume as `.claude-workflows-manifest`, so the thing a running session reads to answer "which commit's process am I running" is now inside the blessed set rather than beside it. Blessing the provenance stamp along with the payload it describes is the correct boundary definition; see the Overall Assessment for the wording.

- **B5 was closed better than filed.** r3 asked for `[ "$EGRESS_DIR" = "/usr/local/share/cc-egress" ]`. What landed is that *plus* a separate, differently-named knob (`CC_EGRESS_OWNER_CHECK`) that turns the check **on** for a relocated directory — so the override family no longer contains any variable whose presence turns a boundary assertion **off**, and the test knob's name says what it does. That is a genuinely better answer than the one recommended, and `test/init-firewall-rules.bats:987-989` exercises it.

- **The sudoers hunk states the premise every `CC_*` override rests on, in the artefact rather than in prose.** `Dockerfile:429` now emits `Defaults:node env_reset, !setenv` and a bare-invocation grant (`init-firewall.sh ""`). Every "test override `node` cannot pass" comment in `init-firewall.sh` — there are five — was true only because of a sudoers line that said nothing about it and inherited `env_reset` from the base image's defaults. Now the guarantee is written where it is enforced, and the `""` additionally takes the four `--print-*` hooks off the root-runnable surface, which is r2's A5 answered from the artefact end. *(route: code-fact-check — that `Defaults:node env_reset, !setenv` parses and behaves as claimed under this image's sudo version is a `visudo` question, and `docs/reviews/execution-logs/cfc-lp3-sudoers-visudo-563448a.txt` exists; I did not re-run it.)*

- **`daemonize`'s bounded wait tracks a dependency across a module boundary in the right direction.** The lock's scope change happened in `init-firewall.sh`; the response happened in `cc-sni-proxy.py`, and its comment (`:258-259`) names the caller's lock as the reason. The proxy still knows nothing about the firewall's rules — only about the fact that its caller is holding something while it starts, which is a legitimate thing for a daemonizing child's parent to bound. The `SIGKILL`-then-`waitpid`-then-return-1 path also leaves no orphan for the next run's `stop_prior` to find.

- **The verification block stopped duplicating work it had already done.** The old standalone `-t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI` check was deleted when the loop absorbed it, and the comment at `:1104-1105` was rewritten to point at the loop ("the nat rule itself was asserted above") rather than left describing a check that had moved. Absorbing a check into a general mechanism *and* fixing the comment that referenced it is the half people skip.

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| C1 | The `claude-home` walk is `-type f`, so non-regular entries are installed and `COPY`ed but never blessed — one exists today (`workflows/workflows`, an absolute symlink into the maintainer's host home); additions of this class are invisible to `check_manifest` | Coupling | `cc-isolated.sh:71`, `:77-93`, `install.sh:42-52`, `Dockerfile:403` | High |
| C2 | The five `-C` assertions verify presence, but for the two `-I OUTPUT 1` DNS redirects and the `127.0.0.11` guard jump the script's own comments say **position** is the invariant; `-C` cannot see it, and the new comment claims the block covers "every rule the boundary depends on" | Coupling | `init-firewall.sh:1039-1053`, `:763-768`, `:816-817`, `:846-852` | High |
| C3 | Five rule literals now appear three times each (install, `-C`, bats); B7's "self-detecting, so optional" no longer holds at this count, and a match-only array factors cleanly and makes C2's `-I 1` vs `-C` difference visible | Minor | `init-firewall.sh:816-817`, `:850`, `:1018`, `:1028`, `:1039-1047` | High |
| C4 | Lock is in the right layer with no double-locking or `postStartCommand`/re-assert ordering hazard, but the wait is now a whole run (~270 s modelled, 600 s cap) and `flock -w` is silent — a contended re-assert looks like a hang, and Ctrl-C lands on the fail-closed trap | Minor | `init-firewall.sh:336-370`, `cc-isolated.sh:420-437` | High |
| C5 | B6 unchanged: log grammar declared at the producer only; the truncate-on-start half still declared only in argparse help while the probe depends on it | Coupling | `cc-sni-proxy.py:157-161`, `:250`, `init-firewall.sh:1107` | High |
| C6 | B4 unchanged and one responsibility heavier: the unnamed region ahead of phase A now holds traps, ownership assertion, compose, parse **and** the lock; five regions, two banners | Informational | `init-firewall.sh:299-370` | Medium |
| C7 | Registry-test residues: `awk '{print $2}'` mis-parses a flagged `COPY`; the skip list cannot fail if `enforcement_files()` loses the glob or the walk; one 136-char comment line | Minor | `test/cc-isolated-functions.bats:504`, `:507-520`, `cc-isolated.sh:51` | High |

---

### Overall Assessment

**No. No Structural finding remains open.** B2 — carried from r2 through r3 as the single Structural item — is closed. `enforcement_files()` now walks `claude-home` and `compute_manifest()` batches the hash, in that order; all 104 regular files in the staged payload are blessed, `.manifest` included; a bats case proves an edit under `claude-home/` trips `check_manifest`; and the comment that used to assert coverage it did not have now describes coverage it does. B1, B3, B5 and B8 are also closed. B4 and B6 remain open at Informational and Coupling respectively, both unchanged in kind. The seven findings above are three Coupling, three Minor and one Informational; none of them is a structural defect in the shipped boundary, and the highest-value one (C2) is a gap between a new control and what it claims, not a gap in the boundary itself.

**Q1 — is B2 closed as Structural, and is hashing `.manifest` sound or churn?** Closed, and sound. The churn worry does not survive contact with `install.sh`: the stamp is a pure function of `HEAD`, tree-dirtiness and `REPO_ROOT`, and `install.sh:109` re-blesses at the end of every install run, so (a) re-running the installer at an unchanged commit produces a byte-identical manifest, and (b) when it *does* change, the change is exactly the event a human should be re-approving. There is no path where `.manifest` moves without the installer running, and no path where the installer runs without re-blessing. Recommended decision-log wording (as a row in `docs/decisions/log.md`, not a full record — single clear answer, no live tradeoff):

> **`--bless` means "this exact payload, assembled from this exact commit".** `enforcement_files()` walks `claude-home` file by file, including the `.manifest` provenance stamp `install.sh` writes (`commit`, `dirty`, `assembled_from`). Blessing the stamp alongside the payload it describes is the point: the manifest records *which* process the image ships, not just that some process was approved. It is not a churn source — the stamp is a function of `HEAD` and tree-dirtiness, not of run count, and `install.sh` re-blesses as its last step, so a re-install at the same commit is a no-op. Known limit: the walk is `-type f`, so a non-regular entry added under `claude-home` is installed and `COPY`ed without being blessed (see architecture r4 C1); this closes decision 016's manifest gap for content, not for the empty-file classes.

The one honest caveat, worth the second sentence of that row: `assembled_from=$REPO_ROOT` is an absolute host path, so a blessed manifest is specific to one checkout location. Correct for this repo's single-maintainer, local-only model; it would need revisiting if the config were ever blessed on one machine and verified on another.

**Q2 — are the tests now the single source of truth, and is the remaining hand-maintenance acceptable?** Nearly, and yes. Of the six directed edges among `PAYLOAD`, `enforcement_files()` and the Dockerfile's `COPY` sources, two are now asserted (`PAYLOAD ∖ {dirs} ⊆ enforcement_files`, `{COPY} ⊆ PAYLOAD`) and two more are covered by construction rather than assertion: `egress` by a glob that is exactly as wide as its only consumer (`compose_domains` opens `$EGRESS_DIR/$p.txt` and nothing else), and `claude-home` by the walk. That is the right allocation — assert the edges where two hand-maintained literals must agree, and let construction cover the edges where one mechanism subsumes a whole directory. The tests are the source of truth for *agreement*; they are not yet the source of truth for *non-emptiness*, which is C7's one substantive line: the skip list cannot fail if the glob or the walk is deleted from `enforcement_files()`. Add `grep -q "^$item/"` inside the `case` and the hand-maintenance that remains — the six literal names in `enforcement_files()`, which must match `PAYLOAD` — is fully pinned in one direction and acceptable in the other, since a name in `enforcement_files()` that is *not* in `PAYLOAD` fails loudly at `compute_manifest`'s existence check on the next launch.

**Q3 — is the lock in the right layer; any double-locking or ordering hazard?** Right layer, no double-locking, no ordering hazard between `postStartCommand` and the launcher's re-assert. The script is the only mutator of the boundary and two of its three invocation paths never touch the launcher, so a launcher-side lock would cover one path in three; the re-assert calls the same baked script and therefore takes the same lock in a fresh process, with nothing nested. `devcontainer up` awaits `postStartCommand`, and the re-assert only runs after `up` returns and a probe fails — strictly sequential within a run, and the case the re-assert exists for is precisely the one where `postStartCommand` did not run at all. Both daemon starts still close fd 9 so neither can park the lock; the proxy's new `READY_TIMEOUT` closes the one remaining way a child could have. What the wider scope costs is visibility (C4): the wait went from sub-second to a whole run, `flock -w` says nothing while it waits, and the operator's view is a launcher line that sits silent for minutes. Three lines of `flock -n`-then-announce-then-block fixes it.

**Q4 — is a shared rules array now worth it?** Yes, and the answer flipped from r3 for a countable reason: one pair became five, and each pair has a third copy in the bats suite. The self-detection argument still holds for the script's two copies and does not extend to the tests, which fail on a *reformat*. More usefully, the factoring that r3 said did not work cleanly does work if the array holds only the match (`-p tcp --dport 53 -j CC_DNS`) and each site keeps its own chain-and-position prefix — and that shape makes C2's problem visible at the call site, because `-I OUTPUT 1` and `-C OUTPUT` end up adjacent and obviously different instead of buried in two long strings 220 lines apart. Take C3 and C2's comment fix in one commit.

**Q5 — net effect on the eventual split.** Net neutral, with one improvement and one new obligation. 1087 → 1116 lines, which continues not to be the constraint. The improvement: the phase-A→phase-B implicit interface (~18 globals) gained nothing this pass, so the expensive cut is no worse than at r3. The new obligation: the lock now spans both phases, so a `phase-a.sh`/`phase-b.sh` split can no longer put the lock inside either half — it becomes a property of the *caller*, which means the split's first task is a wrapper that takes the lock and invokes both, and that wrapper is now the fail-closed trap's owner too. That is a real constraint but a clarifying one: it names the thing the split has to produce (a thin serialising driver) instead of leaving it to be discovered. The hook seam is fully intact — all four `--print-*` hooks still exit ahead of the trap, the ownership assertion and the lock (`:73`, `:113`, `:161`, `:237` vs `:299`, `:301`, `:365`), and the sudoers `""` now makes that structurally enforced rather than merely true. The composition-lib extraction remains the cheap cut; take it first, and take it before the lock wrapper.

**Recommended order.** C2's two assertions or its comment narrowing (the only finding where a control claims more than it checks) → C3's match arrays, same commit → C1's one-line non-regular assertion, which is what makes B2's close hold → C7's `grep "^$item/"` line, which is what makes B1's close hold → C4's three-line `flock -n` announce → C5's two comment lines → C6's banner opportunistically. A6, the A4 residues and the undeclared SNI-allowlist-file grammar (r3's Q3 residue) stay parked.

### Goal-Alignment Note
- **Answered: yes.** The gate question is answered explicitly and in the negative — **no Structural finding remains open at `f313de7`**. B2, the single Structural item carried from r2 through r3, is closed by the batched `sha256sum` plus the sorted `claude-home` walk, verified against the staged payload (104 of 104 regular files hashed). B1, B3, B5 and B8 also close; B4 and B6 remain open at Informational and Coupling. All eight prior findings carry a status row with evidence. The five questions are answered: (1) B2 closed, `.manifest` hashing is sound and not churn — the stamp is a function of `HEAD`/dirtiness and the installer re-blesses as its last step — with the decision-log row drafted verbatim above and the `assembled_from` caveat named; (2) the tests are now the source of truth for registry *agreement* on two of six edges with two more covered by construction, and the one missing line is an assertion that each skipped prefix is non-empty in `enforcement_files()`' output; (3) the lock is in the right layer with no double-locking and no `postStartCommand`/re-assert ordering hazard, and the residual cost is silence during a now-much-longer wait; (4) yes, the shared array is now worth it — five pairs plus five test copies, and a match-only array factors cleanly and exposes C2; (5) net neutral, the phase interface did not grow, and the split now has a named first task (a serialising driver that owns the lock and the trap).
- **Out of scope:** whether presence-without-position is *reachable* given today's straight-line install block (a control-flow question I answered as "no, today" but did not exhaustively verify against every abort path); the sudoers line's parse behaviour under this image's sudo version (routed to code-fact-check, which has an execution log); IPv6 policy; ClientHello parsing; allowlist content; the design of `test/init-firewall-rules.bats` beyond reading its lock/`-C` cases as coverage evidence; the `find`/`stat` additions to the script's runtime dependency set. No `security-review-…-r4.md` existed at the time of writing (`ls docs/reviews/ | grep r4` → no matches), so no finding carries an r4 boundary label; C1 and C2 are routed to that pass under the r3 labels sec-B2 and sec-N2.
- **Escalate:** (1) **C2 is the one finding where a new control claims more than it checks** — the `-C` loop's comment says "every rule the boundary depends on must actually be present", while the script's own capitalised ORDER OF OPERATIONS comment at `:763` says position, not presence, is the invariant for three of the five. Nothing today can produce the divergence, but the comment is the one a future maintainer will believe. (2) **C1 is B2's residue and it is populated, not hypothetical** — `claude-home/workflows/workflows` is an absolute symlink into the maintainer's host home that is installed, `COPY`ed, and never blessed; it cannot smuggle content (it is dangling in the image), but `check_manifest` cannot see an *added* entry of that class. One assertion closes it. (3) **C4 changed the failure mode of contention rather than removing it** — a contended re-assert is now a silent multi-minute wait behind a launcher line that says "Re-asserting …", and the operator's instinct there is Ctrl-C, which lands on the fail-closed trap. (4) **B6/C5 is the cheapest open item in the backlog with a real failure mode behind it** and has now survived three passes unchanged.
