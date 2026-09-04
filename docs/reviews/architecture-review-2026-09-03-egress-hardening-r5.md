# Architecture Review — egress hardening pass 5, f313de7..294a6c2

Commit: 294a6c2

**Scope:** `git diff f313de7..294a6c2 -- devcontainer-config/` — `cc-isolated.sh` (the manifest region read as one unit: `enforcement_files()` `:44-78`, `compute_manifest()` `:80-106`, `bless_manifest()` `:108-114`, `check_manifest()` `:116-136`), `init-firewall.sh` (1116 → 1137; the `EGRESS_DIR_DEFAULT` constant `:41-45`, the trap `:272-311`, the ownership assertion `:314-330`, the lock block `:349-387`, the verification loop `:1056-1078`) — plus the two new bats cases in `test/cc-isolated-functions.bats:531-551`. Read as committed context but not themselves reviewed: `test/init-firewall-rules.bats` (+18/−7, read as coverage evidence for the lock and `-C` changes), `guides/cc-isolated-usage.md` (+3), `docs/working/questions.md` (+1), `docs/reviews/*-r4.md`. Unchanged in this range and therefore not re-read: `cc-sni-proxy.py`, `Dockerfile`, `install.sh`, `egress/`.
**Date:** 2026-09-03
**Based on:** `docs/reviews/architecture-review-2026-09-03-egress-hardening-r4.md` (on `f313de7`, findings C1–C7). My labels this pass are `D1`–`D7`.

**Trust-boundary cross-reference:** `docs/reviews/security-review-2026-09-03-egress-hardening-r5.md` does not exist (`ls docs/reviews/*r5*` → no matches at the time of writing), so **no finding below carries an r5 boundary label**. Where a boundary is named I use the r3 security labels (**sec-B<n>**, **sec-N<n>**) as r4 did, and flag which the r5 security pass should rule on.

---

### Prior findings status

| Prior # | Finding (r4) | Status | Evidence |
|---|---|---|---|
| C1 | The `claude-home` walk was `-type f`, so non-regular entries were installed and `COPY`ed but never blessed; one exists today (`workflows/workflows`) | **closed, with two residues (D1, D3)** | `:76` is now `find claude-home \( -type f -o -type l \)`, `compute_manifest` `:86-94` splits the listing into `files[]`/`links[]`, and `:101-104` hashes each link's target text. Verified against the staged payload in this working tree: `find claude-home -type f` → 104, `-type l` → 1, `! -type d ! -type f ! -type l` → **0**, so the walk is now complete for everything that exists (the "one character" recommendation, taken as the wider of the two options r4 offered). `test/cc-isolated-functions.bats:541-551` proves a repoint trips `check_manifest`. Residues: the walk's *completeness* is still uncheckable (D1) and the link branch is a second output format (D3). |
| C2 | Nine—then five—`-C` assertions verify presence while the script's own capitalised comment says position is the invariant for three | **partly: the loop widened, the comment narrowed, and the narrowing under-names the set (D5)** | The loop went 5 → 9 rules (`:1062-1071`), absorbing the two `! -d 127.0.0.1` DNS guards, the ipset ACCEPT and the terminal REJECT — strictly more coverage. r4 offered "two assertions, or narrow the comment"; the comment was narrowed (`:1058-1061`, "presence only — the position of the two `-I OUTPUT 1` DNS redirects is by construction, not re-checked"). But position is load-bearing for **seven** of the nine now, not two — see D5. The banner move (`:1056-1057` now precedes the loop) is a real legibility gain. |
| C3 | Five rule literals × three copies each; a match-only array is warranted | **not done, and the count grew** | Nine literals now, still written twice in the script (`:816-817`, `:866-868`, `:1018`, `:1044`, `:1050`, `:1053` vs `:1063-1071`) and seven times in `test/init-firewall-rules.bats:926,982-988`. See D4 — answer to Q4 unchanged in kind, larger in degree, and now **debt, not a pass-5 item**. |
| C4 | The lock wait is up to 600 s and completely silent; Ctrl-C on the apparent hang lands on the fail-closed trap | **half-addressed, and the unaddressed half is now inconsistent with the addressed one (D2)** | `LOCK_TIMED_OUT=1` at `:384` makes a *timed-out* waiter report and stand down instead of forcing DROP — a genuine improvement, and the right call. But r4's recommended `flock -n`-then-announce was not taken (`:379` is still a bare `flock -w`), so the silence that produces the Ctrl-C is unchanged, and an *interrupted* waiter — identical state, touched nothing — still forces DROP over the holder's boundary. |
| C5 | Log grammar declared at the producer only; truncate-on-start undeclared | **open, unchanged** | `cc-sni-proxy.py` is untouched in this range (`git diff f313de7..294a6c2 -- devcontainer-config/cc-sni-proxy.py` → empty); `init-firewall.sh:1128` still greps the grammar with no pointer back. Four passes unchanged. Not re-filed below. |
| C6 | The unnamed region ahead of PHASE A holds five responsibilities | **open, unchanged in kind; one global heavier** | No `PRECONDITIONS` banner. The region `:310-387` is byte-identical in shape; what changed is that the trap it opens with now reads **two** prologue globals instead of one (D2). Not re-filed below except as D2's structural half. |
| C7 | Registry-test residues (`awk '{print $2}'`; the skip list cannot fail if a mechanism is deleted; a 136-char comment) | **not done** | `test/cc-isolated-functions.bats:496-529` is untouched in this range; `cc-isolated.sh:51` is still 136 characters (the new symlink sentences were wrapped correctly, so the block is now 75–85 chars everywhere *except* that one pre-existing line). Two new test residues joined it — D7. |

---

### Dependency Map

**Manifest coverage — the walk is now complete, and the completeness is still unverifiable.** The producer/consumer split is `enforcement_files()` (emits names) → `compute_manifest()` (hashes them). This range widened the producer (`-type f` → `\( -type f -o -type l \)`) and taught the consumer a type distinction it did not previously have. The edge between them is still a **process substitution** (`done < <(enforcement_files)`, `:95`), whose exit status bash discards by construction. That is the seam the pass-4 bug travelled down: the producer died mid-listing, the consumer saw a short list and could not tell. The new `[ "${#files[@]}" -gt 0 ]` guard at `:96` closes the *total-emptiness* case only, which is not the case that fired (six unconditional `echo`s at `:59-64` sit outside the subshell, so `files[]` was never empty). See D1.

**Type classification now happens twice.** `find \( -type f -o -type l \)` classifies each entry at `:76`; `compute_manifest` re-classifies the same entries with `[ -L ]`/`[ ! -f ]` at `:86-94`. The producer knows the answer and throws it away; the consumer recovers it with a second `stat` per entry (~111 today). Two classifiers over one truth, with no shared vocabulary between them. This is the honest core of Q1 — see D3.

**Manifest ordering moved from the producer to the consumer.** At `f313de7` the manifest's line order *was* `enforcement_files()`'s emission order (six fixed names, then two sorted globs, then a sorted walk). At `294a6c2` the final `| LC_ALL=C sort -k2` at `:105` re-sorts everything by path, so the producer's ordering discipline (three separate `LC_ALL=C sort`s at `:71`, `:72`, `:76`) is now redundant for the manifest and load-bearing only for a human reading `enforcement_files` output directly. Harmless, and the global sort is the more robust contract — but the file now sorts four times to guarantee one property.

**Trap ↔ prologue — a second global, and a third state that has no flag.** `fail_closed_on_abort` (`:274-309`) now reads `LOCK_TIMED_OUT` (`:273`, set at `:384`) *and* `FIREWALL_COMPLETE` (`:272`, set at `:1137`). Three reachable states across two booleans, with precedence encoded in check order rather than in the data. The phase-A→phase-B implicit interface (~18 globals) did not grow; the *trap's* implicit interface did, from one global to two. See D2.

**Rule installation ↔ rule verification — the edge widened from 5 to 9, and stayed presence-only.** `:1062-1071` now queries rules installed at `:816-817` (`-I OUTPUT 1` ×2), `:866-868` (`-A` ×3, all of which must precede `-o lo -j ACCEPT` at `:869`), `:1018`, `:1044`, `:1050` and `:1053` (which must be last). Of the nine, seven have a position invariant that `-C` cannot see; the new comment names two of the seven. See D5.

**`EGRESS_DIR_DEFAULT` — a one-line improvement to a two-place literal.** `:44` names the baked path once and `:45` and `:323` both reference it, removing the one place where a relocation could silently disable the ownership assertion by string drift. The `CC_EGRESS_OWNER_CHECK` test also tightened from `-n` to `= "1"`. Both are the same move as B5 and both are right.

---

### Findings

#### D1 — The producer→consumer seam still discards a truncated listing; the new guard closes the one case that could not fire

**Severity:** Coupling
**Trust boundary:** sec-B2 (host-side config dir → `check_manifest()` → image build). Re-rule requested from the r5 security pass.
**Location:** `devcontainer-config/cc-isolated.sh:66-78`, `:95`, `:96`, `:108-114`
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** High
**Evidence:**
> ```
>   done < <(enforcement_files)
>   [ "${#files[@]}" -gt 0 ] || { echo "ERROR: enforcement file list is empty" >&2; return 1; }
> ```

(`cc-isolated.sh:95-96`; read with the whole of `enforcement_files()` `:55-78`, `compute_manifest()` `:80-106` and `check_manifest()` `:116-136`.) Against the six unconditional emissions that sit *outside* the failing subshell:
> ```
>   echo "devcontainer.json"
>   echo "Dockerfile"
>   echo "init-firewall.sh"
>   echo "cc-sni-proxy.py"
>   echo "link-claude-home.sh"
>   echo "cc-isolated.sh"
> ```

(`:59-64`.) And the fix itself:
> ```
>     # `[ ! -e ] ||` rather than `[ -e ] &&`: under set -e + pipefail the latter's
>     # false status on an empty glob killed this subshell before the walk below.
>     for f in egress/*.txt; do [ ! -e "$f" ] || echo "$f"; done | LC_ALL=C sort
> ```

(`:69-71`.)

**Legibility-target:** for-author

**Direct answer to Q2: no, the subshell is not the right structure — but the subshell is not the sensitivity either.** The `set -e` interaction is a symptom; the structural fault is that `compute_manifest` consumes `enforcement_files` through a process substitution, and **bash discards a process substitution's exit status by construction**. There is no `set -e` setting, no `pipefail`, and no `shopt` that makes `done < <(f)` notice that `f` died. So the seam converts "the producer failed" into "the producer produced less", silently, at both `--bless` time and `check_manifest` time.

Why that matters more than the instance: the six names at `:59-64` are emitted *before* the subshell, so `files[]` is never empty on this path. The pass-4 bug produced a six-entry manifest, not a zero-entry one — and the guard added at `:96` to answer it triggers only at zero. It is a guard against the one shape the failure cannot take. If the walk at `:76` dies (a `find` permission error inside `claude-home`, `pipefail` on the `| sort`, any future tail command with a non-zero last status), `--bless` writes a manifest missing the entire baked payload and `check_manifest` computes the same short list and **passes**. That is B2's failure mode returning through a different door, and B2 was the Structural finding this whole review chain was opened on.

Why I hold it at Coupling rather than Structural: today's code has no reachable truncation. The two globs are now status-safe; `if [ -d claude-home ]; then …; fi` returns 0 when the condition is false (bash: an `if` with no else and a false condition exits 0), so the fresh-install path is genuinely fixed; and `cd "$cfg" || return 0` at `:68` fails safe downstream, because the six fixed names then fail `[ ! -f "$cfg/$f" ]` at `:89`. The exposure is entirely prospective. But this file already carries **three** separate comments explaining a `set -e` workaround (`:69`, `:185`, `:205`) — the class is not hypothetical here, it is the file's most-commented hazard, and this pass added the third instance-level comment rather than removing the class.

**Recommendation.** Two lines, in this order:

1. **Propagate the status.** Replace the process substitution with a captured string:
   ```
   local listing
   listing="$(enforcement_files)" || { echo "ERROR: enforcement file listing failed" >&2; return 1; }
   while read -r f; do … done <<< "$listing"
   ```
   This removes the whole sensitivity class rather than this instance, and it is the answer to Q2. (Keeping the subshell inside `enforcement_files` is fine — `cd` needs the isolation and `pushd`/`popd` would be worse. The subshell is not the problem; the *unchecked* subshell is.)
2. **Make the count a machine-side check, not just an operator-side one.** `bless_manifest`'s new `($(wc -l …) entries)` line (`:110`) is a genuinely good addition and is currently the only completeness signal — but it is addressed to a human at bless time, and `check_manifest` has no equivalent. Either assert a floor (`[ "${#files[@]}" -ge 6 ]` is worthless; `grep -q '^.\{64\}  claude-home/'` on the computed output is not) or, better, assert per-prefix non-emptiness — which is the same one-line assertion r4's C7 asked for on the test side, and it belongs on **both** sides.

---

#### D2 — The trap's state machine is implicit across two booleans, and the state it does not have is the one C4 named

**Severity:** Coupling
**Trust boundary:** the fail-closed control itself. Re-rule requested from the r5 security pass (availability-side, not exposure-side).
**Location:** `devcontainer-config/init-firewall.sh:272-311`, `:379-386`, `:1137`, `test/init-firewall-rules.bats:945-957`
**Move:** 1 (single responsibility), 2 (responsibility boundaries)
**Confidence:** High
**Evidence:**
> ```
> FIREWALL_COMPLETE=0
> LOCK_TIMED_OUT=0
> fail_closed_on_abort() {
>   local chain policies open=0
>   if [ "${LOCK_TIMED_OUT:-0}" = "1" ]; then
>     echo "ERROR: init-firewall.sh gave up waiting for the lock; the ruleset was left as the" >&2
>     echo "       concurrent run leaves it (not forced to DROP — this run changed nothing)." >&2
>     return 0
>   fi
>   if [ "${FIREWALL_COMPLETE:-0}" != "1" ]; then
> ```

(`init-firewall.sh:272-281`; the whole trap `:274-309` and both `trap` installs `:310-311` were read with it.) Against the only site that sets the new flag:
> ```
> if ! flock -w "$FIREWALL_LOCK_WAIT" 9; then
>     echo "ERROR: could not take $FIREWALL_LOCK within ${FIREWALL_LOCK_WAIT}s — another init-firewall.sh run is still in progress" >&2
>     # This run touched nothing; the holder is building (or has built) the boundary.
>     # Forcing DROP here would tear down THAT run's work, so the trap is told to
>     # report and stand down instead of failing closed.
>     LOCK_TIMED_OUT=1
>     exit 1
> fi
> ```

(`:379-386`.) And the interrupt handler that reaches the same trap from the same wait:
> ```
> trap 'exit 143' INT TERM HUP QUIT
> ```

(`:311`.)

**Legibility-target:** for-author

**Direct answer to Q3: implicit, across two flags — and the implicitness has a live consequence.** The machine has three reachable states and two booleans:

| `LOCK_TIMED_OUT` | `FIREWALL_COMPLETE` | meaning | trap does |
|---|---|---|---|
| 0 | 0 | may have mutated, or never got that far | force DROP |
| 1 | 0 | never held the lock, touched nothing | report, stand down |
| 0 | 1 | complete | nothing |
| 1 | 1 | unreachable | — |

Precedence lives in the *order of the two `if`s*, not in the data, and the fourth cell is unreachable only by convention. That is the definition of implicit. But the readable cost is the smaller half; the real one is this:

**The stand-down predicate is "did we time out", when the fact it stands for is "did we ever hold the lock".** Those diverge on exactly the path C4 escalated. An operator watching `cc-isolated.sh:423`'s `Re-asserting firewall …` line sit silent for minutes (r4's C4, unchanged this pass — `:379` is still a bare `flock -w` with no announce) presses Ctrl-C. `SIGINT` → `trap 'exit 143'` → `EXIT` → `LOCK_TIMED_OUT` is **still 0**, because it is only ever set on `flock`'s own failure → `FIREWALL_COMPLETE` is 0 → the trap forces `-P OUTPUT DROP` on a container whose boundary the *holder* is mid-build. Same harm the new flag was added to prevent, same state ("this run changed nothing"), opposite outcome — and now inconsistent in a way a reader of `:381-383` would not predict, because that comment states the general principle ("this run touched nothing") while the flag encodes a specific cause.

This is availability, not exposure: DROP is the safe direction and the recovery is documented at `:305-307`. It stays Coupling for that reason. But it is the finding where a control added this pass covers less than its own comment claims, which is the same species as C2 and worth the same treatment.

**Recommendation.** One variable instead of two, three lines of diff, and it closes the Ctrl-C path for free:

```
RUN_STATE=preconditions          # replaces FIREWALL_COMPLETE=0 / LOCK_TIMED_OUT=0
…
RUN_STATE=awaiting-lock          # immediately before the flock at :379
if ! flock -w "$FIREWALL_LOCK_WAIT" 9; then … exit 1; fi
RUN_STATE=holding                # immediately after
…
RUN_STATE=complete               # replaces FIREWALL_COMPLETE=1 at :1137
```
with the trap standing down on `awaiting-lock` and forcing DROP on anything but `complete`. Note the state must be `awaiting-lock` *before* the `flock` call, not after its failure — that is precisely what makes the interrupt path correct. Do **not** be tempted by the simpler-looking `LOCK_HELD` inversion: aborts that happen *before* the lock (the ownership assertion at `:323-330`, the malformed-profile parse at `:337-347`) currently force DROP and `test/init-firewall-rules.bats:1000` asserts it. A three-valued state preserves that; a two-valued "did we mutate" predicate would silently relax it.

Take r4's C4 announce (`flock -n` first, then say "waiting up to Ns…", then block) in the same commit. It is three lines, it removes the operator's reason to press Ctrl-C, and it is the other half of this finding.

---

#### D3 — `compute_manifest` has two producers and two classifiers; the second producer does not reproduce the format the comment says it uses

**Severity:** Coupling
**Location:** `devcontainer-config/cc-isolated.sh:76`, `:84-94`, `:98-105`
**Move:** 1 (single responsibility), 3 (module boundary)
**Confidence:** High
**Evidence:**
> ```
>   # One sha256sum for the whole list (the claude-home walk is ~100 files; a fork
>   # per file made every launch pay for it). Symlinks are hashed by their target
>   # text, in sha256sum's own output format, so a repoint changes the manifest.
>   (
>     cd "$cfg" && sha256sum "${files[@]}"
>     for f in "${links[@]}"; do
>       printf '%s  %s\n' "$(printf '%s' "$(readlink "$f")" | sha256sum | cut -d' ' -f1)" "$f"
>     done
>   ) | LC_ALL=C sort -k2
> ```

(`cc-isolated.sh:98-105`, read with the classification loop `:84-95` and the producer `:66-78`.) Against what `sha256sum`'s output format actually is when a name needs escaping:
> ```
> $ printf 'x' > 'a\b'; sha256sum 'a\b'
> \2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881  a\\b
> ```

(run in this working tree; coreutils prefixes the line with `\` and doubles backslashes / escapes newlines in the name. The `printf '%s  %s\n'` branch at `:103` emits the name verbatim and never prefixes.)

**Legibility-target:** for-author

**Direct answer to Q1: a clean-enough seam with one dishonest edge, and the batching is worth keeping — but the split is in the wrong place.** Taking the three sub-questions in order:

**Is the batching worth the split?** Yes, unambiguously, and I would not undo it. `check_manifest` runs on every launch over ~111 entries; one `sha256sum` fork versus 111 is the reason r4 recorded the batch-then-widen ordering as the best thing in that range. A single loop with per-entry dispatch would re-introduce exactly the cost that ordering was designed to avoid, for one symlink. **Do not take the "single honest loop" option.**

**Is it a second manifest format hiding inside the first?** Very nearly not, and it is one line from being genuinely not. Field layout, hash width and the two-space separator all match, and `sort -k2` merges them into one order-stable stream. The divergence is the escaping rule: `sha256sum` has a documented line-level escape for names containing `\` or newline, and the `printf` branch does not implement it. So a symlink named `a\b` produces a line that `sha256sum -c` would parse differently from the line the same name would get as a regular file — two formats, distinguishable only on names that do not occur in `claude-home` today. Low-stakes, but the comment ("in sha256sum's own output format") is a claim the code does not quite honour, and that is the class of claim this review chain has spent four passes correcting. *(route: code-fact-check — "in sha256sum's own output format" and "the Dockerfile COPYs them"; I confirmed the latter empirically (`cp -r` preserves links; `COPY` of a directory does not dereference) but the Dockerfile is out of this range's scope.)*

**Where the split actually is wrong.** Not between the two hash producers — between the two *classifiers*. `find \( -type f -o -type l \)` at `:76` already knows each entry's type and discards it; `:86-94` then re-derives it with a `[ -L ]` plus a `[ ! -f ]` per entry (~111 `stat`s, quietly giving back a slice of what the batching bought, and opening a TOCTOU window between walk and classify that is theoretical but real). The honest factoring keeps the batch and removes the double work: have `enforcement_files` emit a type tag it already has (`f<TAB>path` / `l<TAB>path`, with the six fixed names tagged `f`), and let `compute_manifest` bucket on the tag while keeping the existence check for the fixed names only. That is one type-decision in one place, two buckets, one `sha256sum` — and it makes the emptiness question of D1 answerable per-bucket.

**Recommendation.** Keep the batch. Take the escaping honesty one way or the other: either implement the prefix-and-escape rule in the link branch, or narrow the comment to "one line per entry, `<hash>  <path>`; regular-file lines are `sha256sum`'s and link lines are constructed to match, which is exact for names without backslashes or newlines" — and, since `claude-home` names are generated by `install.sh`, add the assertion that makes the narrower claim safe rather than merely true. The single-classifier refactor is optional and pairs naturally with D1's status propagation.

---

#### D4 — Nine rule literals, still written twice in the script and seven times in the tests

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:816-817`, `:866-868`, `:1018`, `:1044`, `:1050`, `:1053`, `:1063-1071`, `test/init-firewall-rules.bats:926`, `:982-988`
**Move:** 7 (coupling surface)
**Confidence:** High
**Evidence:**
> ```
> iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD
> iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
> iptables -A OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
> iptables -A OUTPUT -o lo -j ACCEPT
> ```

(`init-firewall.sh:866-869`.) Against the assertion copies:
> ```
>     "-C OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD" \
>     "-C OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD" \
>     "-C OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD" \
> ```

(`:1066-1068`) and the test copies (`test/init-firewall-rules.bats:985-988`, which now also carry the `-w 5` prefix, so a change to the *wait flag* breaks seven greps as well).

**Legibility-target:** for-author

**Direct answer to Q4: still true, and it is debt, not a pass-5 item.** The arithmetic moved the wrong way — five pairs became nine, and the test side went from five literals to seven, each of which now also encodes `-w 5`. The r4 argument is unchanged and I will not restate it. What *has* changed is the priority ordering, and I want to be explicit about it because r4 put C3 second in its recommended order:

This is a mechanical refactor with a green suite on either side and no behavioural content. D1, D2 and D5 all describe controls that claim more than they check. Spending the confirming pass's commit on a rename-shaped change, in a file where four consecutive passes have found comment-versus-control gaps, inverts the risk. The match-array factoring also becomes *easier* after D5 is settled, not harder — once the position invariants are either asserted or accurately named, the array's shape (match-only, chain-and-position at each site) follows from that decision rather than pre-empting it.

**Recommendation.** Park it as debt with a named trigger rather than a date: **take it the next time a rule is added or a rule literal changes.** At that moment the cost of the refactor is paid anyway (three sites to edit) and the array removes the third and subsequent edits forever. Record it in `docs/decisions/log.md` alongside the manifest row so it does not silently become permanent. The r4 sketch stands as the implementation.

---

#### D5 — The "presence only" caveat names two rules; seven of the nine have a position invariant

**Severity:** Coupling
**Trust boundary:** sec-N2. Re-rule requested from the r5 security pass.
**Location:** `devcontainer-config/init-firewall.sh:1058-1061`, `:1062-1071`, `:763-768`, `:816-817`, `:866-869`, `:1044`, `:1050`, `:1053`
**Move:** 1 (single responsibility), 7 (coupling surface)
**Confidence:** High
**Evidence:**
> ```
> # The load-bearing rules must actually be present (presence only — the position of
> # the two `-I OUTPUT 1` DNS redirects is by construction, not re-checked). `-C`
> # queries what `-A`/`-I` installed; drift between the two literals is
> # self-detecting (the run aborts into DROP).
> ```

(`init-firewall.sh:1058-1061`, the rewritten comment above the nine-rule loop `:1062-1078`.) Against the four *other* position invariants the script states in its own voice:
> ```
> iptables -A OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD
> iptables -A OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
> iptables -A OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
> iptables -A OUTPUT -o lo -j ACCEPT
> ```

(`:866-869` — all three guard jumps are dead if they land after the loopback accept; the block comment at `:832-836` says so: "Jumped to (before the loopback accept)".) And:
> ```
> iptables -A OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD
> …
> iptables -A OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT
> …
> iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
> ```

(`:1044`, `:1050`, `:1053` — the guard must precede the ipset ACCEPT, per `:1036-1039` "the ipset accept below must never be reachable by the agent for 443 directly", and the terminal REJECT is a catch-all whose entire meaning is being last. `test/init-firewall-rules.bats:788-790` asserts the guard/ACCEPT ordering, so the property is already recognised as load-bearing on the test side.)

**Legibility-target:** for-author

C2, half-taken. Widening the loop to nine was the right move and closes the coverage half outright. Narrowing the comment was the option r4 offered as the cheap alternative to asserting position — but the narrowing names the two `-I OUTPUT 1` redirects and stops, and the count is seven:

| assertion | position invariant | stated at |
|---|---|---|
| `-t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI` | none (appended) | — |
| `-t nat -C OUTPUT -p {udp,tcp} --dport 53 -j CC_DNS` | must be nat OUTPUT 1 | `:763-766`, named in the new comment |
| `-C OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD` | before `-o lo -j ACCEPT` | `:832-836` |
| `-C OUTPUT -p {udp,tcp} --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD` | before `-o lo -j ACCEPT` | `:832-836` |
| `-C OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD` | before the ipset ACCEPT | `:1036-1039` |
| `-C OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT` | after the guards | `:1036-1039` |
| `-C OUTPUT -j REJECT --reject-with icmp-admin-prohibited` | last | by definition |

A comment that says "presence only — the position of *the two DNS redirects* is by construction" reads as an exhaustive caveat. A maintainer who adds a tenth rule, or who moves the loopback accept, will read it as licence. That is strictly worse than r4's original comment, which over-claimed uniformly and was therefore uniformly distrusted; this one is precise and incomplete, which is the shape that gets believed.

Nothing today can produce presence-without-position — the rules are installed unconditionally in straight-line blocks with no `|| true` — so this remains a comment-versus-control gap, not a boundary gap. Unchanged from r4 in kind.

**Recommendation.** Either generalise the caveat in one line — "presence only. Seven of these nine also have a position invariant (nat OUTPUT 1 for the DNS redirects `:763`; ahead of `-o lo -j ACCEPT` for the three DNS guards `:869`; ahead of the ipset ACCEPT for the SNI guard `:1044`; last for the REJECT). Position is guaranteed by the single straight-line install block, not by this loop." — or take r4's two ordering assertions, which now cover more ground than they did at five rules:
```
iptables -t nat -S OUTPUT | head -2 | grep -c 'dport 53 -j CC_DNS'   # expect 2
iptables -S OUTPUT | grep -n -e 'CC_DNS_GUARD' -e 'CC_SNI_GUARD' -e '-o lo -j ACCEPT' \
                             -e 'allowed-domains' -e '-j REJECT'      # compare line numbers
```
The second form asserts five of the seven in one read. If that is too clever for this file, take the comment — but do not leave the current wording, for the same reason r4 gave.

---

#### D6 — `2>/dev/null` on the `-C` loop collapses "rule absent" and "iptables failed" into one message

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:1073-1077`
**Move:** 6 (substitutability)
**Confidence:** High
**Evidence:**
> ```
>     IFS=' ' read -r -a rule_args <<< "$rule"
>     if ! iptables -w 5 "${rule_args[@]}" 2>/dev/null; then
>         echo "ERROR: Firewall verification failed - expected rule missing: iptables $rule"
>         exit 1
>     fi
> ```

(`init-firewall.sh:1072-1077`.)

**Legibility-target:** for-author

Two good changes and one seam. `-w 5` is right — the loop now waits for the xtables lock like every other call in the file instead of being the one place that could fail on contention; and it is the same `-w 5` the fail-closed trap uses, so the two agree. Suppressing stderr is also defensible in intent: `iptables -C` prints `iptables: Bad rule (does a matching rule exist in that chain?).` on a clean miss, which is noise above the script's own message.

But `iptables` distinguishes these by exit status — `1` for "no such rule", `2` for a usage/parameter error — and the branch does not. So a genuinely malformed assertion string (a typo in a rule literal, which D4 makes nine times more likely than at r3) reports "expected rule missing", the run aborts into DROP, and the diagnostic points at the firewall instead of at the typo. Same for a permissions or kernel-module failure. The output that would have said which is discarded one character earlier.

The failure direction is safe — everything ends at DROP — so this is Minor. It is a diagnosis-quality cost on the one path where the operator is already looking at a bricked container.

**Recommendation.** Four lines, no new literals:
```
    rc=0; iptables -w 5 "${rule_args[@]}" 2>/dev/null || rc=$?
    if [ "$rc" = "1" ]; then
        echo "ERROR: Firewall verification failed - expected rule missing: iptables $rule"; exit 1
    elif [ "$rc" != "0" ]; then
        echo "ERROR: Firewall verification could not run (iptables exit $rc): iptables $rule"; exit 1
    fi
```
Both still abort into DROP; only the sentence changes.

---

#### D7 — Two residues in the new tests: one vacuous assertion, and "every boundary rule" is eight of nine

**Severity:** Minor
**Location:** `test/init-firewall-rules.bats:952-957`, `:980-989`, `test/cc-isolated-functions.bats:531-539`
**Move:** 7 (coupling surface), 8 (extension points)
**Confidence:** High
**Evidence:**
> ```
>   # A lock timeout must NOT tear down the boundary the holder is building.
>   run grep -c -- "-P OUTPUT DROP" "$CMD_LOG"
>   [ "$output" -eq 0 ]
>   [[ "$output" != *"fails CLOSED"* ]]
> ```

(`test/init-firewall-rules.bats:953-956`. `run grep …` overwrites `$output` with grep's count — `"0"` — so the third line tests grep's output for the script's message and can never fail. Contrast `:699`, where the identical idiom immediately follows `run bash "$FW"` and is meaningful.) And:
> ```
> @test "every boundary rule is asserted present before completion" {
>   …
>   grep -q "^iptables -w 5 -C OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD$" "$CMD_LOG"
> ```

(`:980-989` — seven greps for nine assertions. `-t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI` is covered elsewhere at `:926`; **`-C OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD` is covered nowhere**, so the tcp half of the new DNS-guard pair could be dropped from the loop and the suite named "every boundary rule" would stay green.)

**Legibility-target:** for-author

Both are one-liners and neither changes a conclusion, but they land on the two assertions this range was written to add, which is why they are worth naming rather than absorbing into C7.

The vacuous line matters more than it looks: it is the *only* assertion standing between D2's finding and a regression, and the finding it half-covers (a timed-out waiter must not print the fail-closed banner) is exactly the behaviour the new `LOCK_TIMED_OUT` flag exists to produce. Fix: capture the script's output before the greps —
```
CC_FIREWALL_LOCK_WAIT=1 run bash "$FW"
fw_output="$output"
…
[[ "$fw_output" != *"fails CLOSED"* ]]
[[ "$fw_output" == *"not forced to DROP"* ]]
```
The second line is the positive assertion the test is missing entirely — right now nothing checks that the new stand-down *message* is produced, only that DROP is absent, and DROP would also be absent if the trap never ran.

The new `cc-isolated-functions.bats` cases are both well-built and I want to say so specifically: running through `bash -euo pipefail -c 'source …; compute_manifest'` rather than bats' `run` is the right call and the comment says why ("Run through a real errexit shell, not `run`"), because bats' `run` disables `set -e` inside the invoked command and would have passed against the pre-fix code. That is the test being written against the *mechanism* of the bug rather than its symptom. The one gap is scope: it asserts the walk reached `claude-home`, not that the listing was complete — so it pins this instance, which is the correct scope for a regression test, and leaves D1's class to D1.

**Recommendation.** Add the eighth grep at `:988`, capture `fw_output` at `:949`, and add the positive `"not forced to DROP"` assertion. Take with C7's `grep "^$item/"` line in one test-only commit.

---

### What Looks Good

- **The `--bless` entry count is the right kind of small addition.** `bless_manifest` printing `($(wc -l < …) entries)` (`:110`) gives the human doing the blessing a single number to sanity-check, and it is the artefact that would have made the pass-4 bug visible at the moment it was introduced — a maintainer who blessed six entries where the last bless said 111 would have stopped. Adding an operator-legible invariant *at the approval gate* is a better response to "a silent truncation shipped" than another internal assertion would have been, because the gate is where a human is already paying attention. It does not close D1 (nothing compares the two numbers), but it is the half that costs one line.

- **The symlink close chose the wider of r4's two options and the payload is now provably complete.** r4 offered "hash link targets" or "assert no non-regular entries exist"; the wider one landed, and `find claude-home ! -type d ! -type f ! -type l | wc -l` → 0 in this tree confirms there is no third class left unhandled. The comment at `:73-75` states the *reason* the class matters (`cp -r` preserves links → `COPY` carries them → a repoint changes the served payload without changing the manifest), which is the causal chain, not just the change. *(route: code-fact-check — "install.sh's cp -r preserves links, the Dockerfile COPYs them". I verified `cp -r` preserves symlinks empirically and Docker's `COPY` of a directory does not dereference, but `install.sh` and the `Dockerfile` are outside this range and the claim spans three files.)*

- **`EGRESS_DIR_DEFAULT` removes a string-drift hazard from a boundary assertion, and the knob got stricter in the same hunk.** `:44-45` and `:323` now share one literal, so the ownership check can no longer be silently disabled by editing the default path in one place — and `CC_EGRESS_OWNER_CHECK` moved from `-n "${…}"` to `= "1"`, so an accidental empty-ish value (`0`, `false`) no longer enables it. The comment `:41-43` also states, once and centrally, the premise every `CC_*` comment in the file leans on (sudo `env_reset`, no `SETENV`), instead of repeating it five times. This is B5's fix generalised correctly.

- **The verification banner moved above the check it announces.** `echo "Verifying firewall rules..."` at `:1057` now precedes the `-C` loop instead of following it, so a run that aborts on a missing rule prints the banner and then the failure, rather than failing under the *previous* banner. Small, and it makes the tail region's four sub-blocks legible in the log without a code banner — a partial, free answer to C6 that I did not expect from this range.

- **A timed-out lock waiter no longer tears down the holder's boundary.** Setting the fail-closed trap to stand down when this run demonstrably changed nothing is the correct semantics, and the comment at `:381-383` states the reasoning ("Forcing DROP here would tear down THAT run's work") rather than the mechanism. D2 is a complaint about the predicate's shape, not about this judgement, which is right.

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| D1 | `compute_manifest` consumes `enforcement_files` through a process substitution, whose exit status bash discards by construction; the new `${#files[@]} -gt 0` guard closes only total emptiness, which is the one shape the pass-4 failure could not take (six names are emitted outside the failing subshell) | Coupling | `cc-isolated.sh:66-78`, `:95-96` | High |
| D2 | The trap's three states live in two booleans with precedence encoded in check order; the stand-down predicate is "did we time out" rather than "did we ever hold the lock", so an operator's Ctrl-C during the still-silent wait forces DROP over the holder's in-progress boundary | Coupling | `init-firewall.sh:272-311`, `:379-386` | High |
| D3 | Two hash producers merged by `sort -k2` and two independent type classifiers (`find` at `:76`, `[ -L ]` at `:86`); the link branch does not implement `sha256sum`'s line escaping that the comment claims it matches | Coupling | `cc-isolated.sh:76`, `:84-94`, `:98-105` | High |
| D4 | C3 unchanged and larger: nine rule literals, twice in the script and seven times in the tests, now also encoding `-w 5` | Minor | `init-firewall.sh:816-817`, `:866-868`, `:1063-1071`, `test/init-firewall-rules.bats:982-988` | High |
| D5 | The rewritten "presence only" caveat names the two `-I OUTPUT 1` redirects; seven of the nine assertions have a position invariant the script states elsewhere in its own voice — precise-and-incomplete is more believable, and therefore worse, than the over-claim it replaced | Coupling | `init-firewall.sh:1058-1071`, `:866-869`, `:1044-1053` | High |
| D6 | `2>/dev/null` on the `-C` call discards the distinction `iptables` encodes in its exit status (1 = absent, 2 = error), so a typo'd literal reports "expected rule missing" | Minor | `init-firewall.sh:1073-1077` | High |
| D7 | Test residues on the two new controls: `[[ "$output" != *"fails CLOSED"* ]]` after `run grep` is vacuous, and "every boundary rule" greps eight of nine (the tcp/53 `! -d 127.0.0.1` guard is asserted nowhere) | Minor | `test/init-firewall-rules.bats:952-957`, `:980-989` | High |
| — | C5 (log-grammar contract) and C6 (unnamed region) carried open, unchanged; not re-filed | Coupling / Informational | `cc-sni-proxy.py:157-161`, `init-firewall.sh:310-387` | High / Medium |

---

### Overall Assessment

**No. No Structural finding is open at `294a6c2`.** The gate is answered in the negative for the second consecutive pass, and this pass strengthens rather than merely preserves that answer: C1 — B2's last residue, and the only finding in the chain with a populated instance — is closed, and the closure is verifiable rather than argued (`find claude-home ! -type d ! -type f ! -type l` → 0 in the staged payload, so the widened walk has no remaining uncovered class, and `test/cc-isolated-functions.bats:541-551` proves a repoint trips `check_manifest`). C2 is half-closed by widening the loop from five rules to nine. C4 is half-closed on its worse half. The seven findings above are three Coupling, four Minor; none is a defect in the shipped boundary, and none of the three Coupling items describes a path by which the boundary opens — D1 and D3 are about the manifest's *verifiability*, D2 and D5 about controls whose comments outrun what they check, and D2's failure direction is DROP.

I want to be explicit about the one finding that has a Structural-shaped shadow, because a confirming pass should say where the next Structural finding would come from if one came. **D1 is the door B2 came through, and this range closed the instance rather than the class.** The manifest's completeness is the property decision 016's `--bless` exists to guarantee; the seam between its producer and its consumer converts producer failure into silent under-coverage; and the guard added to answer the pass-4 bug triggers only at zero entries, which is not the shape that bug had. It is not Structural today because there is no reachable truncation left — the two globs are status-safe, `if … fi` with a false condition exits 0, and a missing config dir fails downstream on the six fixed names. It would become Structural the moment anything is appended to that subshell whose last command can fail. Two lines (`listing="$(enforcement_files)" || return 1`) retire the class permanently, and that is the single highest-value item in this report.

**Q1 — clean seam or a second format hiding inside the first?** Clean-enough, one line from genuinely clean, and the batching is worth keeping — do **not** take the single-loop-with-dispatch option. `check_manifest` runs at every launch over ~111 entries; one fork versus 111 is why r4 recorded the batch-then-widen ordering as that range's best change, and undoing it for one symlink would be a real regression. Field layout, hash width, separator and the `sort -k2` merge all line up; the one divergence is that `sha256sum` escapes names containing `\` or newline with a line-leading `\` and the `printf` branch does not, so the comment's "in sha256sum's own output format" is a claim the code does not quite honour on names that do not occur today. The split that *is* misplaced is a different one: `find \( -type f -o -type l \)` already classifies every entry and discards the answer, and `:86-94` re-derives it with ~111 `stat` calls — two classifiers over one truth, giving back a slice of what the batch bought. Emit the type from the producer (`f<TAB>path` / `l<TAB>path`), bucket on it in the consumer, keep the single `sha256sum`.

**Q2 — is the subshell the right structure?** The subshell is fine; the *unchecked* subshell is not. `cd` needs the isolation and `pushd`/`popd` would be worse. The sensitivity class is not `set -e` at all — it is that `done < <(enforcement_files)` discards the producer's exit status by construction, with no shell option that changes it. Building an array and printing once would remove this instance and leave the class (a future `return 1` inside the builder is equally invisible through a process substitution). Capturing the listing into a variable with `|| return 1` removes the class in one line. That this file already carries three separate comments explaining a `set -e` workaround (`:69`, `:185`, `:205`) is the argument for treating it as a class: this pass added the third comment rather than removing the need for one.

**Q3 — explicit or implicit?** Implicit, across two booleans, with precedence in check order and one unreachable-by-convention cell — and the implicitness costs something concrete. The stand-down predicate encodes the *cause* (`LOCK_TIMED_OUT`) where the fact that matters is the *state* ("we never held the lock"). Those diverge on precisely the path C4 escalated: `flock -w` is still silent (r4's `flock -n`-then-announce was not taken), the operator sees a launcher line hang for minutes, presses Ctrl-C, and the interrupt reaches the trap with `LOCK_TIMED_OUT` still 0 — so the same run, in the same state the new comment describes as "this run touched nothing", forces DROP over the holder's in-progress boundary. One three-valued `RUN_STATE` (`preconditions` / `awaiting-lock` / `holding` / `complete`), with `awaiting-lock` set *before* the `flock` call, makes the machine explicit and closes the interrupt path in the same three lines. Resist the simpler `LOCK_HELD` inversion: pre-lock aborts (ownership assertion, malformed profile) must keep forcing DROP, and a test at `:1000` asserts it.

**Q4 — still true, pass-5 item or debt?** Still true and the count grew from five pairs to nine, with the test side now encoding `-w 5` as well. **Debt, not a pass-5 item.** It is a mechanical refactor with no behavioural content, and this pass's other findings are all controls that claim more than they check — spending the confirming pass's commit on a rename-shaped change in a file with four consecutive passes of comment-versus-control gaps inverts the risk. It also gets easier after D5 settles, since the array's shape follows from whether position is asserted or merely named. Give it a trigger rather than a date: take it the next time a rule is added or a literal changes, when the three-site edit is being paid anyway. Record the deferral in `docs/decisions/log.md` so it does not become permanent by silence.

**Q5 — anything that changes the split picture.** Two things, one in each direction, net neutral-to-slightly-worse. **Worse:** the fail-closed trap's implicit interface grew from one prologue global to two (`FIREWALL_COMPLETE` + `LOCK_TIMED_OUT`), which sharpens r4's observation that a `phase-a.sh`/`phase-b.sh` split cannot own the lock — the serialising driver the split has to produce now also owns a *state machine*, not just a flag, and D2's `RUN_STATE` refactor is therefore work the split needs done anyway rather than work it duplicates. Take D2 before the split, not after. **Better:** the verification tail is now self-announcing (`:1056-1057` precedes rather than follows the loop), so the fifth unnamed region is legible in the run log even without C6's banner. The phase-A→phase-B interface (~18 globals) is unchanged; 1116 → 1137 lines continues not to be the constraint. On the launcher side, the manifest region is now 71 lines across four functions with the two-classifier duplication D3 names — still well inside the composition-lib cut r4 identified as the cheap first extraction, and unaffected by it.

**Recommended order.** D1's two-line status propagation (retires the class B2 came from) → D2's `RUN_STATE` plus r4's `flock -n` announce, one commit (closes the last live path where the boundary is torn down by a run that changed nothing) → D5's comment generalisation or the two ordering assertions → D7 plus C7's `grep "^$item/"`, one test-only commit → D3's escaping honesty → D6's exit-status split. D4/C3 parked on a trigger; C5 and C6 stay parked.

### Goal-Alignment Note
- **Answered: yes.** The gate question is answered explicitly and in the negative — **no Structural finding is open at `294a6c2`**, and the pass strengthens the r4 answer rather than merely restating it: C1, the only prior finding with a populated real-world instance (`claude-home/workflows/workflows`), is closed with empirical verification that no uncovered entry class remains in the staged payload. All seven prior findings C1–C7 carry a status row with evidence (C1 closed, C2 and C4 partly, C3 and C7 not done, C5 and C6 open-unchanged). The five questions are answered: (1) clean-enough seam, keep the batching, the real misplacement is the duplicated type classification and the unimplemented escaping rule; (2) the subshell is fine, the unchecked process substitution is the class, one line retires it; (3) implicit across two flags, and the missing third state is exactly the Ctrl-C path C4 escalated; (4) still true, larger, and explicitly **debt with a named trigger**, not a pass-5 item, with the reasoning for the deferral given; (5) the trap's implicit interface grew by one global, which makes D2's state-machine refactor prerequisite work for the split rather than duplicate work, offset by a free legibility gain in the verification tail.
- **Out of scope:** `cc-sni-proxy.py`, `Dockerfile`, `install.sh` and `egress/` (untouched in this range); the *content* of the allowlist and the two-label profile rule the guide now documents (routed to code-fact-check — the guide claim was not verified against `parse_entry`); whether `COPY` and `cp -r` preserve symlinks across all three files the D3 comment spans (I verified both mechanisms empirically in this tree, but the claim's other two files are outside the range); IPv6 policy; ClientHello parsing; the design of `test/init-firewall-rules.bats` beyond reading its lock and `-C` cases as coverage evidence for the two new controls. **No `security-review-2026-09-03-egress-hardening-r5.md` existed when this report was written** (`ls docs/reviews/*r5*` → no matches), so no finding carries an r5 boundary label; D1 is routed to that pass under sec-B2 and D5 under sec-N2, and D2 is routed as an availability-side question (a fail-closed control that fires when it should stand down) rather than an exposure-side one.
- **Escalate:** (1) **D1 is the class the pass-4 bug came from, and this range closed the instance.** The guard added to answer it (`${#files[@]} -gt 0`) triggers only on total emptiness, which is the one shape that failure could not take — six names are emitted outside the subshell that died. Two lines close the class; until then the next tail command added to `enforcement_files` re-opens B2 silently, at both bless and check time. (2) **D2 leaves the two halves of the same situation treated oppositely.** A waiter that times out now stands down; a waiter that is interrupted during the same still-silent wait still forces DROP over the holder's in-progress boundary — and the comment at `:381-383` states the general principle the flag does not implement. r4's `flock -n` announce, unaddressed this pass, is what produces the interrupt. (3) **D5's narrowed caveat is the more believable kind of wrong.** It names two position invariants where seven exist, all five omitted ones stated elsewhere in the script's own capitalised voice; a precise-but-incomplete caveat gets trusted where an over-claim gets checked. (4) **C5 has now survived four passes unchanged** and remains the cheapest open item with a real failure mode behind it (two comment lines; the probe depends on truncate-on-start, which is declared only in argparse help).
