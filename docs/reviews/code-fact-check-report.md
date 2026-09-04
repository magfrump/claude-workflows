# Code Fact-Check Report

**Commit:** 294a6c2
**Replication:** k=1 (loop pass, decision 031)
**Repository:** claude-workflows (/workspace)
**Scope:** Range `f313de7..294a6c2` (HEAD = 294a6c2, one commit), restricted to `devcontainer-config/` — `cc-isolated.sh`, `init-firewall.sh`, plus `egress/base.txt` where the guide sentence duplicates it — the commit message of `294a6c2`, and the "Pass 4" rows marked ✅ Fixed (R8, A32–A35) in `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md`. `guides/cc-isolated-usage.md`, `devcontainer-config/install.sh`, `devcontainer-config/Dockerfile`, `test/*.bats`, `docs/working/questions.md` and the four `*-review-2026-09-03-egress-hardening-r4.md` critic reports are sibling context, consulted as evidence but not themselves under review.
**Checked:** 2026-09-03
**Total claims checked:** 23
**Summary:** 20 verified, 1 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Every executable guarantee in the commit body reproduces exactly: **420/420 bats** (`1..420`, zero `not ok`), **13/13 python**, **shellcheck clean** on all four `devcontainer-config/*.sh`. The four mechanisms this round turns on were **executed**, not reasoned about, and each behaves as the comments say:

1. `set -e` alone does *not* kill the `enforcement_files` subshell on an empty `projects/` glob — `set -e` **plus** `pipefail` does, exactly as the new comment states; the old form drops the whole `claude-home` walk and exits 1, the new form emits it in all three config shapes.
2. Symlinks are hashed by `readlink` text with no dereference: a dangling link hashes fine, a repoint changes the manifest, a directory symlink is hashed by target only and `find` does not walk through it.
3. `${#files[@]}` on an empty array is safe under `set -u` in bash 5.2.15, and `compute_manifest` reaches and fires the new guard.
4. All nine `-C` literals are byte-identical to their `-A`/`-I OUTPUT 1` counterparts (programmatic comparison, exit 0), and real `iptables` v1.8.9 accepts `-w 5` ahead of `-t nat`.

The single defect is a **Stale comment** the same commit created: `init-firewall.sh:367-368` still says a lock failure "ends at DROP like any other abort", which the new `LOCK_TIMED_OUT` early-return in the trap directly contradicts. Comment-only — the behavior is the intended one, and the rubric's A33 row describes it correctly; only the comment 14 lines above the `flock` call now lies about it. One Mostly-accurate finding (the "One sha256sum for the whole list" batching note, now true of the regular-file majority only) and one Unverifiable figure (the rubric's "0 vs 103 hashed lines", which needs the maintainer's real installed config dir).

Prior-report continuity: the `f313de7` report's 5 Mostly-accurate findings were comment imprecisions; the rubric's Pass-4 line "21 claims, 0 Incorrect, 5 comment imprecisions fixed" matches that report's header (`**Total claims checked:** 21`, `16 Verified, 5 Mostly accurate, 0 Incorrect`).

No claim in this pass matched any entry in `docs/reviews/hallucination-patterns.md` (both logged entries are fabricated-corpus-statistic patterns; the one measured figure this round — the rubric's "103 hashed lines" — is Unverifiable here rather than refuted, so it is **not** logged).

---

## Claim 1: "Sorted globs so the manifest is order-stable. An empty projects/ dir is normal (no project has widened its egress yet), hence the -e guard on each match."

**Location:** `devcontainer-config/cc-isolated.sh:64-65`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers order-stability of the two glob blocks and the survival of an empty `projects/` directory; does not establish stability of the `claude-home` walk against a filename containing a newline (which `find`'s newline-separated output and the consumer's `while read -r f` would both mis-split).

The globs are each piped through an explicit `LC_ALL=C sort`, so the emitted order does not depend on the caller's locale:

```bash
# devcontainer-config/cc-isolated.sh:71-72
    for f in egress/*.txt; do [ ! -e "$f" ] || echo "$f"; done | LC_ALL=C sort
    for f in projects/*.profile; do [ ! -e "$f" ] || echo "$f"; done | LC_ALL=C sort
```

Executed against three temp config dirs — (a) empty `projects/`, (b) no `projects/` at all, (c) one `.profile` — the function exits 0 in all three and the `claude-home` walk is present in all three (`claude-home walk present: 1` in each case). The `-e` guard is still an `-e` test, now negated; see Claim 2 for why the polarity changed.

**Evidence:** `devcontainer-config/cc-isolated.sh:64-77`, `docs/reviews/execution-logs/cfc-lp4-enforcement-files-294a6c2.txt`

---

## Claim 2: "`[ ! -e ] ||` rather than `[ -e ] &&`: under set -e + pipefail the latter's false status on an empty glob killed this subshell before the walk below."

**Location:** `devcontainer-config/cc-isolated.sh:69-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism (which shell options are jointly required), the failure it names (the `claude-home` walk being dropped), and the fix's behavior in the three `projects/` shapes; does not establish the fix under any shell other than bash 5.2.15, nor that no *other* construct in the subshell can abort it early.

Executed reproduction of the **old** form against a config dir with an empty `projects/`:

```
exit=1
devcontainer.json
egress/base.txt
OLD claude-home walk present: 0
```

The mechanism named in the comment is precisely the operative one — neither option alone suffices. Running only the offending pipeline under three flag sets:

```
--- flags: -e            → REACHED_WALK, exit=0
--- flags: -eo pipefail  → exit=1        (walk never reached)
--- flags: -u            → REACHED_WALK, exit=0
```

The launcher does set both, at `devcontainer-config/cc-isolated.sh:31`:

```bash
set -euo pipefail
```

The new form emits the walk and exits 0 in all three config shapes (Claim 1's log).

**Evidence:** `devcontainer-config/cc-isolated.sh:31`, `devcontainer-config/cc-isolated.sh:69-76`, `docs/reviews/execution-logs/cfc-lp4-enforcement-files-294a6c2.txt`, `docs/reviews/execution-logs/cfc-lp4-pipefail-mechanism-294a6c2.txt`

---

## Claim 3: "Regular files AND symlinks: install.sh's cp -r preserves links, the Dockerfile COPYs them, so a repointed link would otherwise change the served payload without changing the manifest (symlinks are hashed by their target text)."

**Location:** `devcontainer-config/cc-isolated.sh:73-75`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers `cp -r`'s symlink preservation, the existence of the Dockerfile `COPY` of `claude-home/`, `find`'s inclusion of links, and the manifest-repoint consequence; does **not** establish that Docker's `COPY` itself preserves a symlink rather than dereferencing it (no Docker daemon in this sandbox), and does not establish that the served *container* payload is what the manifest hashes end-to-end.

`cp -r` preserving links (executed):

```
lrwxrwxrwx  dang -> /nowhere
lrwxrwxrwx  link -> real
-rw-r--r--  real
```

install.sh reaches the symlink because `workflows` is in its staging list:

```bash
# devcontainer-config/install.sh:42
CLAUDE_HOME_SRC=(CLAUDE.md skills workflows guides patterns hooks scripts)
```

```bash
# devcontainer-config/install.sh:48
    cp -r "$REPO_ROOT/$item" "$STAGE/$item"
```

and the Dockerfile does COPY the staged tree:

```dockerfile
# devcontainer-config/Dockerfile:403
COPY claude-home/ /opt/claude-workflows/
```

The walk now includes links:

```bash
# devcontainer-config/cc-isolated.sh:76
    if [ -d claude-home ]; then find claude-home \( -type f -o -type l \) | LC_ALL=C sort; fi
```

Executed against a fixture containing a dangling link, a link to a directory, and a link whose path contains a space, all three appear in `enforcement_files` output and in the manifest, and a repoint of the dangling link changes exactly one manifest line (diff captured in the log). `find` does not follow the directory symlink: `claude-home/realdir/inner.txt` appears once, by its real path, and not a second time through `claude-home/skills/dirlink`.

**Evidence:** `devcontainer-config/cc-isolated.sh:73-76`, `devcontainer-config/install.sh:42,48`, `devcontainer-config/Dockerfile:403`, `docs/reviews/execution-logs/cfc-lp4-cpr-symlink-staging-294a6c2.txt`, `docs/reviews/execution-logs/cfc-lp4-symlink-manifest-294a6c2.txt`

---

## Claim 4: "`[ "${#files[@]}" -gt 0 ] || { echo "ERROR: enforcement file list is empty" >&2; return 1; }` — compute_manifest refuses an empty list" (commit body: "compute_manifest refuses an empty list")

**Location:** `devcontainer-config/cc-isolated.sh:96`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `${#files[@]}` on an empty array does not trip `set -u` in bash 5.2.15 and that the guard fires with `return 1` before `sha256sum` is invoked with no operands; does not establish the message's precision — the guard fires when the *regular-file* list is empty even if `links` is non-empty, so the printed text "enforcement file list is empty" can be emitted while the list held only symlinks.

```bash
# devcontainer-config/cc-isolated.sh:96
  [ "${#files[@]}" -gt 0 ] || { echo "ERROR: enforcement file list is empty" >&2; return 1; }
```

Executed under `bash -euo pipefail` (`bash: 5.2.15(1)-release`):

```
--- idiom: ${#arr[@]} on empty array under set -u ---
empty branch reached, no unbound error
exit=0
--- compute_manifest with ALL top-level files as symlinks (files=() empty) ---
ERROR: enforcement file list is empty
exit=1
```

The guard is load-bearing: without it, `sha256sum "${files[@]}"` with no operands would read stdin.

**Evidence:** `devcontainer-config/cc-isolated.sh:96,101`, `docs/reviews/execution-logs/cfc-lp4-empty-array-bless-294a6c2.txt`

---

## Claim 5a: "One sha256sum for the whole list (the claude-home walk is ~100 files; a fork per file made every launch pay for it)."

**Location:** `devcontainer-config/cc-isolated.sh:97-98`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fork count of the two branches inside the manifest subshell; does not establish the "~100 files" figure (that depends on the maintainer's installed `claude-home/`, absent here) nor any wall-clock launch cost.

The batching still holds for regular files — one `sha256sum` for the whole array — but the sentence now precedes a loop that reintroduces per-item forks for the symlink branch:

```bash
# devcontainer-config/cc-isolated.sh:100-105
  (
    cd "$cfg" && sha256sum "${files[@]}"
    for f in "${links[@]}"; do
      printf '%s  %s\n' "$(printf '%s' "$(readlink "$f")" | sha256sum | cut -d' ' -f1)" "$f"
    done
  ) | LC_ALL=C sort -k2
```

Each iteration forks two command substitutions plus `sha256sum` and `cut` — i.e. the pattern the comment says was removed, now scoped to links only. The precise version would be "one `sha256sum` for the whole *regular-file* list; symlinks still cost a fork each, and there are few of them." The comment's conclusion — that the expensive case (the ~100-file walk) is batched — still holds, which is why this is imprecision and not a refuted mechanism.

**Evidence:** `devcontainer-config/cc-isolated.sh:97-105`

---

## Claim 5b: "Symlinks are hashed by their target text, in sha256sum's own output format, so a repoint changes the manifest."

**Location:** `devcontainer-config/cc-isolated.sh:98-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two-space `<hash>  <path>` format, the no-dereference `readlink` hash, and the repoint-trips-manifest consequence for every path that contains neither a backslash nor a newline; does **not** establish format identity for such a path — GNU `sha256sum` escapes those by prefixing the line with `\`, which the `printf '%s  %s\n'` branch does not do (executed below), so the two branches would diverge in format and in `sort -k2` position for such a name. No such path exists in the payload today.

The link branch's output is byte-identical in shape to `sha256sum`'s (both two spaces, `cat -A` shown):

```
81400175...4881  claude-home/skills/dangling$        <- link branch
87428fc5...25c7  egress/base.txt$                    <- sha256sum
```

Hashing is by target text with no dereference: a dangling link (`-> nowhere.txt`) hashes successfully, and repointing it to `elsewhere.txt` changes exactly its own line:

```
-81400175ee7c369247134c7bfeae173d6acce1e04dbaf42f80b49ca5183c2f7e  claude-home/skills/dangling
+0ec7303069be8581eb5581b2c313c20da180925e1b4cccc6522ce6c89a76b780  claude-home/skills/dangling
```

The escaping residue, executed:

```
--- sha256sum on a backslash path ---
\2d711642...4881  d/back\\slash.txt
--- printf form for the symlink branch ---
34a04005...eb5c  d/li\nk
```

**Evidence:** `devcontainer-config/cc-isolated.sh:98-105`, `docs/reviews/execution-logs/cfc-lp4-symlink-manifest-294a6c2.txt`, `docs/reviews/execution-logs/cfc-lp4-sha256-escaping-294a6c2.txt`

---

## Claim 6: "`| LC_ALL=C sort -k2` merges the two branches into an order `check_manifest`'s whole-string compare can rely on"

**Location:** `devcontainer-config/cc-isolated.sh:105`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers run-to-run byte-stability of `compute_manifest`'s output — the only property `check_manifest`'s comparison actually needs — including a path containing a space; does not establish stability across coreutils versions or across a filename containing a newline, which would break the producer's own `while read -r f` loop before `sort` ever saw it.

`check_manifest` compares whole strings, not fields, so format *consistency across runs* is the requirement, not any particular field layout:

```bash
# devcontainer-config/cc-isolated.sh:124-126
  expected="$(cat "$manifest")"
  actual="$(compute_manifest)"
  if [ "$expected" != "$actual" ]; then
```

`sort -k2` with no end-field takes the key from the start of field 2 **to end of line**, so a path containing a space is sorted whole rather than truncated at the space. Executed on a fixture containing `claude-home/skills/good link.md`, two consecutive `compute_manifest` runs are byte-identical (`STABLE: run1 == run2`) and the space-bearing path sorts in its full-path position between `dirlink` and `devcontainer.json`.

**Evidence:** `devcontainer-config/cc-isolated.sh:105,114-133`, `docs/reviews/execution-logs/cfc-lp4-symlink-manifest-294a6c2.txt`

---

## Claim 7: "Blessed $(manifest_path) ($(wc -l < "$(manifest_path)") entries):" (commit body: "Bless prints an entry count")

**Location:** `devcontainer-config/cc-isolated.sh:111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the printed number equals the manifest's line count and its entry count for a manifest written by `compute_manifest`; does not establish behavior if the manifest's final line lacked a trailing newline (`wc -l` would then undercount by one) — `sha256sum` and the `printf '...\n'` branch both terminate every line, so that state is unreachable here.

```bash
# devcontainer-config/cc-isolated.sh:110-112
  compute_manifest > "$(manifest_path)"
  echo "Blessed $(manifest_path) ($(wc -l < "$(manifest_path)") entries):"
  cat "$(manifest_path)"
```

Executed on a 10-entry fixture (6 fixed files, 2 egress profiles, 1 `claude-home` file, 1 `claude-home` symlink):

```
Blessed /tmp/tmp.rsYdU852Vm/manifest.sha256 (10 entries):
actual manifest lines: 10
manifest entries (non-empty): 10
```

`wc -l` runs on the file **after** the redirection completes, so it counts the manifest just written, not a stale one.

**Evidence:** `devcontainer-config/cc-isolated.sh:108-113`, `docs/reviews/execution-logs/cfc-lp4-empty-array-bless-294a6c2.txt`

---

## Claim 8: "A domain needs two or more labels (a bare label such as `com` would become a whole-TLD resolver zone and is rejected)."

**Location:** `devcontainer-config/egress/base.txt:15-16`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `HOST_RE`'s two-or-more-label requirement, its enforcement in `parse_entry`, and the stated dnsmasq rationale; does not establish that every *accepted* two-label form is resolvable, nor that the same grammar gates the CIDR path (GitHub is admitted by address, not by name).

```bash
# devcontainer-config/init-firewall.sh:134-135
HOST_LABEL='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
HOST_RE="^${HOST_LABEL}(\.${HOST_LABEL})+\$"
```

The `+` quantifier on the dotted group makes at least one dot mandatory, i.e. ≥2 labels. Executed through the script's own `parse_entry`:

```
REJECT  com
OK      a.b                            -> a.b	443
OK      api.anthropic.com              -> api.anthropic.com	443
OK      mirror.example:443,8443        -> mirror.example	443,8443
REJECT  host:22
```

and directly against `HOST_RE`: `com`, `localhost`, `a`, `a.`, `.a`, `-a.b` all REJECT; `a.b`, `api.anthropic.com`, `host.docker.internal`, `a-b.c` all ACCEPT. The stated reason matches the in-script rationale:

```
# devcontainer-config/init-firewall.sh:131-133
# or more labels are REQUIRED: a single label is either a TLD — which as a dnsmasq
# `server=/com/` line would forward every .com name upstream and re-open the
# tunnel the resolver exists to close — or a bare host that no profile needs.
```

**Evidence:** `devcontainer-config/egress/base.txt:15-16`, `devcontainer-config/init-firewall.sh:129-146`, `docs/reviews/execution-logs/cfc-lp4-hostre-294a6c2.txt`

---

## Claim 9: "CC_EGRESS_DIR / CC_EGRESS_PROFILE_FILE, like every CC_* variable in this file, exist for the unit tests only: the script runs via sudo (NOPASSWD, env_reset, no SETENV), which strips them, so `node` cannot relocate anything. EGRESS_DIR_DEFAULT is the image's baked path — the ownership assertion below keys on it."

**Location:** `devcontainer-config/init-firewall.sh:40-43`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all eleven `CC_*` names this script actually reads via parameter expansion, the sudoers text backing the env_reset/`!setenv` assertion, and `EGRESS_DIR_DEFAULT`'s use by the ownership check; does not establish that `sudo` at container runtime is the *only* way `init-firewall.sh` is ever invoked (a root shell could set any of these), and does not cover `CC_EGRESS_PROFILE`, which appears in this file only inside a comment (`:11`) and is a Docker **build** arg, not a variable this script reads.

Enumerating every `CC_*` read through `${...}` in the file gives exactly eleven, all of them relocation/override seams with root-owned defaults (paraphrased — no quote available because the claim covers the *absence* of any other `CC_*` read, established by an exhaustive `grep -no '\${CC_[A-Z_]*'` over the file rather than by a single snippet): `CC_FIREWALL_PATH:38`, `CC_EGRESS_DIR:45`, `CC_EGRESS_PROFILE_FILE:46`, `CC_EGRESS_OWNER_CHECK:323`, `CC_FIREWALL_LOCK:370`, `CC_FIREWALL_LOCK_WAIT:371`, `CC_DNSMASQ_CONF:490`, `CC_DNSMASQ_PIDFILE:491`, `CC_SNI_PROXY_BIN:534`, `CC_SNI_RUN_DIR:535`, `CC_SNI_PORT:539`. The other `CC_*` tokens in the file (`CC_DNS`, `CC_SNI`, `CC_DNS_GUARD`, `CC_SNI_GUARD`) are iptables chain names, not variables, so the claim's "variable" qualifier is doing real work.

The sudoers assertion is backed by the file the Dockerfile writes:

```dockerfile
# devcontainer-config/Dockerfile:429
  printf '%s\n' 'Defaults:node env_reset, !setenv' 'node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh ""' > /etc/sudoers.d/node-firewall && \
```

and the constant is defined and consumed as claimed:

```bash
# devcontainer-config/init-firewall.sh:44-45
EGRESS_DIR_DEFAULT=/usr/local/share/cc-egress
EGRESS_DIR="${CC_EGRESS_DIR:-$EGRESS_DIR_DEFAULT}"
```

```bash
# devcontainer-config/init-firewall.sh:323
if [ "$EGRESS_DIR" = "$EGRESS_DIR_DEFAULT" ] || [ "${CC_EGRESS_OWNER_CHECK:-}" = "1" ]; then
```

**Evidence:** `devcontainer-config/init-firewall.sh:40-46,323`, `devcontainer-config/Dockerfile:407-410,429`

---

## Claim 10: "The assertion keys on the INVARIANT — the directory is the image's baked one — not on whether a test override is present. CC_EGRESS_OWNER_CHECK=1 is a test-only OPT-IN that forces the check on a relocated directory; it can only add a check, never remove one, and env_reset strips it under sudo like every other CC_* variable."

**Location:** `devcontainer-config/init-firewall.sh:317-322`
**Type:** Invariant / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "can only add, never remove" property of the disjunction and the `= "1"` comparison replacing the previous `-n` truthiness; does not establish what the ownership check itself asserts (the `stat`/`find -perm /022` body is unchanged by this commit and was verified in earlier passes).

The guard is a disjunction whose left operand is the invariant, so the env var can only ever widen the set of runs that are checked:

```bash
# devcontainer-config/init-firewall.sh:323
if [ "$EGRESS_DIR" = "$EGRESS_DIR_DEFAULT" ] || [ "${CC_EGRESS_OWNER_CHECK:-}" = "1" ]; then
```

There is no branch anywhere that makes `CC_EGRESS_OWNER_CHECK` *skip* the check (paraphrased — no quote available because the claim is about the absence of such a branch; `grep -no 'CC_[A-Z_]*'` finds exactly one occurrence of the name in the file, at `:323`, inside the guard's own condition). The `= "1"` form is a real tightening over `f313de7`'s `[ -n "${CC_EGRESS_OWNER_CHECK:-}" ]`, under which any non-empty value — including `0` or `false` — enabled it:

```bash
# git show f313de7:devcontainer-config/init-firewall.sh :311
if [ "$EGRESS_DIR" = "/usr/local/share/cc-egress" ] || [ -n "${CC_EGRESS_OWNER_CHECK:-}" ]; then
```

**Evidence:** `devcontainer-config/init-firewall.sh:314-330`

---

## Claim 11: "if [ "${LOCK_TIMED_OUT:-0}" = "1" ]; then … return 0 — a timed-out lock waiter reports and stands down without forcing DROP" (commit body: "A timed-out lock waiter no longer forces DROP over the holder's boundary.")

**Location:** `devcontainer-config/init-firewall.sh:273-281`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the flag's initialization ordering, its single assignment site, the trap's early return, and the absence of any pre-lock ruleset mutation; does **not** establish that the repo's held-lock bats test would catch a regression in the *message* half of this — its last assertion, `[[ "$output" != *"fails CLOSED"* ]]` at `test/init-firewall-rules.bats:956`, inspects `$output` from the immediately preceding `run grep -c`, whose value is `0`, so that one line is vacuous (the `-P OUTPUT DROP` count assertion two lines above it is the real check and does hold).

`LOCK_TIMED_OUT` is initialized before the function is defined and before the trap is installed:

```bash
# devcontainer-config/init-firewall.sh:272-273
FIREWALL_COMPLETE=0
LOCK_TIMED_OUT=0
```

```bash
# devcontainer-config/init-firewall.sh:310
trap fail_closed_on_abort EXIT
```

The trap's first act is the early return, ahead of every `iptables -P … DROP` call:

```bash
# devcontainer-config/init-firewall.sh:275-281
fail_closed_on_abort() {
  local chain policies open=0
  if [ "${LOCK_TIMED_OUT:-0}" = "1" ]; then
    echo "ERROR: init-firewall.sh gave up waiting for the lock; the ruleset was left as the" >&2
    echo "       concurrent run leaves it (not forced to DROP — this run changed nothing)." >&2
    return 0
  fi
```

There is exactly one assignment of `LOCK_TIMED_OUT=1`, at `:384`, immediately inside the `flock` failure branch and immediately before `exit 1` — so it is set on any `flock` failure (timeout or otherwise) and on no other path (paraphrased — no quote available because the claim is about the assignment being unique across the file; `grep -n 'LOCK_TIMED_OUT'` returns exactly `:273` init, `:276` read, `:384` set).

On the "was the ruleset touched?" question the answer is no: the lock is taken at `:380`, and every `iptables`/`ipset`/`ip6tables` invocation appearing before line 385 lies inside the body of `fail_closed_on_abort` (`:283-292`), which has not run at that point. Phase A begins after the lock at `:390`; the first mutating `iptables` call is far below.

**Evidence:** `devcontainer-config/init-firewall.sh:272-311,378-386`, `test/init-firewall-rules.bats:944-958`

---

## Claim 12: "Taken after the trap, so a lock failure ends at DROP like any other abort."

**Location:** `devcontainer-config/init-firewall.sh:367-368`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only this sentence's second clause (the DROP consequence); the first clause ("Taken after the trap") remains true, and the claim is **comment-only** — the runtime behavior is the intended new one and the rubric's A33 row describes it correctly.

The comment was accurate when written — it entered at `6eaa9a0` ("close the pass-2 re-review findings") and is present verbatim at `f313de7:devcontainer-config/init-firewall.sh:355` — and `294a6c2` is the commit that falsified it. What the code now does on a lock failure is the opposite of what this sentence says:

```bash
# devcontainer-config/init-firewall.sh:364-369
# one. The lock lives in a 0700
# root directory so `node` cannot open the file and hold the lock itself (flock
# works on a read-only fd; a 0644 file in /run would let the agent veto every
# re-assert). Taken after the trap, so a lock failure ends at DROP like any other
# abort. CC_FIREWALL_LOCK / CC_FIREWALL_LOCK_WAIT exist for the unit tests only;
# under sudo env_reset `node` cannot set them.
```

versus, fifteen lines later:

```bash
# devcontainer-config/init-firewall.sh:380-385
if ! flock -w "$FIREWALL_LOCK_WAIT" 9; then
    echo "ERROR: could not take $FIREWALL_LOCK within ${FIREWALL_LOCK_WAIT}s — another init-firewall.sh run is still in progress" >&2
    # This run touched nothing; the holder is building (or has built) the boundary.
    # Forcing DROP here would tear down THAT run's work, so the trap is told to
    # report and stand down instead of failing closed.
    LOCK_TIMED_OUT=1
    exit 1
fi
```

A reader acting on `:367-368` — for instance, reasoning that a contended launch leaves the container closed, or removing the `LOCK_TIMED_OUT` branch as redundant with the trap — would be misled. The precise version is: taken after the trap, so a lock failure still *runs* the trap, but the trap recognises this one abort and stands down instead of forcing DROP.

**Evidence:** `devcontainer-config/init-firewall.sh:364-369,275-281,380-386`, `git show f313de7:devcontainer-config/init-firewall.sh` line 355

---

## Claim 13: "This run touched nothing; the holder is building (or has built) the boundary. Forcing DROP here would tear down THAT run's work, so the trap is told to report and stand down instead of failing closed."

**Location:** `devcontainer-config/init-firewall.sh:381-383`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers "this run touched nothing" as a statement about the ruleset at the moment `LOCK_TIMED_OUT` is set; does not establish anything about non-ruleset side effects this run did have (it created `$(dirname "$FIREWALL_LOCK")` at `0700` and the lock file at `0600` at `:377-379`, both idempotent), nor about what the *holder* has actually completed.

The lock acquisition sits ahead of phase A, which the file's own banner marks as the first thing that happens:

```bash
# devcontainer-config/init-firewall.sh:389-392
# ===========================================================================
# PHASE A — RESOLVE EVERYTHING FIRST, WHILE THE OLD FIREWALL IS STILL UP.
```

and the only `iptables`/`ipset` invocations textually above the `LOCK_TIMED_OUT=1` assignment are inside `fail_closed_on_abort`'s unexecuted body at `:283-292` (paraphrased — no quote available because the claim covers the absence of any *other* such invocation in lines 1–384, established by filtering `grep -n 'iptables\|ipset\|ip6tables'` to `$1<385` and finding only comment lines plus the trap body). The bats held-lock test corroborates behaviorally that a timed-out run emits no `-F` flush, no `curl`, no `dig` and no `-P OUTPUT DROP`.

**Evidence:** `devcontainer-config/init-firewall.sh:376-392`, `test/init-firewall-rules.bats:944-958`

---

## Claim 14: "The two paths are env-overridable for the unit tests only: this script runs via sudo (NOPASSWD, no SETENV), whose env_reset strips them, exactly as for CC_EGRESS_DIR above."

**Location:** `devcontainer-config/init-firewall.sh:487-489`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the forward reference now resolves to real text above it in the same file; does not re-verify the sudoers semantics themselves (Claim 9 covers those).

At `f313de7` this was a dangling reference: the only mention of `CC_EGRESS_DIR` above it was the bare assignment, with no surrounding text about env_reset or test-only status —

```bash
# git show f313de7:devcontainer-config/init-firewall.sh :40
EGRESS_DIR="${CC_EGRESS_DIR:-/usr/local/share/cc-egress}"
```

— so "exactly as for CC_EGRESS_DIR above" pointed at nothing a reader could compare against. At `294a6c2` the referent exists, four lines of it, at `:40-43` (quoted in Claim 9). The two passages agree on substance: `:40` says "sudo (NOPASSWD, env_reset, no SETENV), which strips them"; `:488` says "sudo (NOPASSWD, no SETENV), whose env_reset strips them".

**Evidence:** `devcontainer-config/init-firewall.sh:40-43,487-491`

---

## Claim 15: "The load-bearing rules must actually be present (presence only — the position of the two `-I OUTPUT 1` DNS redirects is by construction, not re-checked). `-C` queries what `-A`/`-I` installed; drift between the two literals is self-detecting (the run aborts into DROP)."

**Location:** `devcontainer-config/init-firewall.sh:1058-1061`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all nine literals' byte-identity with their install-site counterparts, the `-w 5` placement's acceptance by real `iptables`, the `2>/dev/null` redirection, the loop's position relative to the "Verifying" banner, and the "presence only" scoping; does **not** establish that the nine rules are the complete set the boundary depends on (the `-o lo` accept at `:869` and the ESTABLISHED accept at `:949` are not asserted), nor that `-C` matching implies correct rule *order* in the filter chain.

All nine `-C` literals are byte-identical to their install-site counterparts once `-C` is rewritten as `-A` (or as `-I OUTPUT 1` for the two nat DNS redirects). Programmatic comparison against exact-line `grep -qxF` over the script, exit 0:

```
MATCH(-A) : -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI
MATCH(-I1): -t nat -C OUTPUT -p udp --dport 53 -j CC_DNS
MATCH(-I1): -t nat -C OUTPUT -p tcp --dport 53 -j CC_DNS
MATCH(-A) : -C OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD
MATCH(-A) : -C OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
MATCH(-A) : -C OUTPUT -p tcp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD
MATCH(-A) : -C OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD
MATCH(-A) : -C OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT
MATCH(-A) : -C OUTPUT -j REJECT --reject-with icmp-admin-prohibited
exit=0
```

The `-w 5` sits ahead of the whole literal, including the `-t nat` prefix:

```bash
# devcontainer-config/init-firewall.sh:1072-1076
    IFS=' ' read -r -a rule_args <<< "$rule"
    if ! iptables -w 5 "${rule_args[@]}" 2>/dev/null; then
        echo "ERROR: Firewall verification failed - expected rule missing: iptables $rule"
        exit 1
    fi
```

Real `iptables v1.8.9 (nf_tables)` accepts that argument order — executed non-root, every vector reached the privilege check rather than a usage error:

```
--- iptables -w 5 -t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI
exit=4
iptables v1.8.9 (nf_tables): Could not fetch rule set generation id: Permission denied (you must be root)
```

The loop is now below the banner:

```bash
# devcontainer-config/init-firewall.sh:1056-1062
echo "Firewall configuration complete"
echo "Verifying firewall rules..."
# The load-bearing rules must actually be present (presence only — the position of
# the two `-I OUTPUT 1` DNS redirects is by construction, not re-checked). `-C`
# queries what `-A`/`-I` installed; drift between the two literals is
# self-detecting (the run aborts into DROP).
for rule in \
```

"aborts into DROP" holds because the `exit 1` on a missing rule occurs while `FIREWALL_COMPLETE=0` and `LOCK_TIMED_OUT=0`, so the EXIT trap takes the DROP branch. Note that the error message re-prints `$rule` without the `-w 5`, which is what `test/init-firewall-rules.bats:1014` asserts.

**Evidence:** `devcontainer-config/init-firewall.sh:832-833,866-868,1034,1044,1050,1053,1056-1078`, `docs/reviews/execution-logs/cfc-lp4-rule-literals-294a6c2.txt`, `docs/reviews/execution-logs/cfc-lp4-iptables-argorder-294a6c2.txt`

---

## Claim 16: "Profile entries are `domain[:port[,port...]]`; a domain needs two or more labels (a bare `com` would become a whole-TLD resolver zone and is rejected)."

**Location:** `guides/cc-isolated-usage.md:276-277`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grammar sentence's accuracy against `HOST_RE`/`parse_entry` and its placement immediately before the `## SNI filtering (tcp/443)` heading; does not establish that the guide's *surrounding* sections are accurate, and does not cover the default-port half of the grammar (`443` when the suffix is absent), which the guide sentence does not state.

The sentence sits at `:276-277`, two lines above the heading at `:279` (blank line between), i.e. as the last paragraph of the preceding probe section — matching the commit's "the guide states the two-label rule". Its content is the same claim verified in Claim 8, executed against the same `parse_entry`: `com` REJECT, `a.b` / `api.anthropic.com` / `host.docker.internal` ACCEPT. The wording matches `devcontainer-config/egress/base.txt:15-16` almost verbatim, so the two documents cannot drift apart silently in one direction only.

**Evidence:** `guides/cc-isolated-usage.md:270-279`, `devcontainer-config/init-firewall.sh:134-146`, `docs/reviews/execution-logs/cfc-lp4-hostre-294a6c2.txt`

---

## Claim 17a: "R8 … ✅ Fixed — `[ ! -e ] ||` in both globs; new test runs `compute_manifest` through a real `bash -euo pipefail` with an empty `projects/`" (including "the bats test could not see it because `run` disables errexit")

**Location:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:184`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fix's presence in both globs, the new test's existence and its use of a real errexit shell, and the diagnosis that bats `run` masked the bug; does not establish the "0 vs 103" figure (Claim 17b) and does not establish that the new test would catch every future variant of the same class (it fixes the fixture at one empty-`projects/` shape).

The fix is in both globs (`cc-isolated.sh:71-72`, quoted in Claim 1), and the new test does run through a real errexit shell rather than `run`:

```bash
# test/cc-isolated-functions.bats:531-538
@test "compute_manifest covers claude-home even when projects/ is empty, under errexit" {
  …
  out="$(bash -euo pipefail -c 'source "$1"; compute_manifest' _ "$CONFIG_SRC/cc-isolated.sh")"
  echo "$out" | grep -q 'claude-home/skills/s.md'
}
```

The blind-spot diagnosis was reproduced directly: a reconstructed bats test sourcing `f313de7`'s **old** `cc-isolated.sh` and calling `run compute_manifest` with an empty `projects/` passes with `status=0` and the `claude-home` payload present in `$output` — because `run` disables errexit, the failing pipeline no longer aborts the subshell and execution falls through to the `find`:

```
status=0
…  claude-home/payload.md
ok 1 OLD compute_manifest under bats run, empty projects/
```

The same old code run as a real `bash -euo pipefail` script exits 1 with the walk absent (Claim 2's log). So the bug was real and the old test could not see it, exactly as the row says.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:184`, `test/cc-isolated-functions.bats:531-538`, `docs/reviews/execution-logs/cfc-lp4-old-test-blindspot-294a6c2.txt`, `docs/reviews/execution-logs/cfc-lp4-enforcement-files-294a6c2.txt`

---

## Claim 17b: "Measured 0 vs 103 hashed lines."

**Location:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:184`
**Type:** Performance / Configuration
**Verdict:** Unverifiable
**Confidence:** High (in the blocker, not in the figure)
**Verification mode:** static
**Scope:** Covers only the specific integer 103; the "0" half is confirmed (Claim 2's old-form repro emits zero `claude-home/` lines), and the directional claim is Verified under 17a.

The figure counts `claude-home/` lines in a manifest computed against the maintainer's **installed** `~/.config/claude-devcontainer/`, which does not exist in this sandbox (paraphrased — no quote available because the claim is about a runtime measurement over an absent directory, not about any line of source). Reproducing it would require either that installed tree or a full `devcontainer-config/install.sh` run staging `CLAUDE.md skills workflows guides patterns hooks scripts` from this repo — the latter would produce a number tied to today's repo contents rather than to the state measured at review time, so it would not confirm or refute the recorded value. Matches the shape of, but is not an instance of, the two logged hallucination patterns (both of which were *refuted* corpus statistics); this one is simply unreachable from here.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:184`, `devcontainer-config/install.sh:42-52`

---

## Claim 18: "A32 … the repo tracks `workflows/workflows` as an absolute symlink into the maintainer's home, dangling in any other checkout. ✅ Fixed — symlinks included in the walk and hashed by target text; repoint trips the manifest (test). Removing the tracked symlink is logged as a question, not done here"

**Location:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:185`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the symlink's existence, mode, absolute target, its path into the image payload, the walk/hash fix, the repoint test, and the logged question; does not establish that this is the *only* symlink that will ever reach the payload (it is the only one tracked in git today) nor that the link is in fact dangling on any particular other machine.

```
120000 53e3ac66de163f41f3cac571b46894dda438c282 0	workflows/workflows
lrwxrwxrwx 1 node node 41 Mar 25 11:47 workflows/workflows -> /home/magfrump/claude-workflows/workflows
```

Mode `120000` is git's symlink mode and the target is absolute into `/home/magfrump`. It reaches the payload because `workflows` is in `install.sh:42`'s `CLAUDE_HOME_SRC` and `cp -r` preserves links (Claim 3). The repoint test exists and passes as part of the 420:

```bash
# test/cc-isolated-functions.bats:541-550
@test "a symlink in claude-home is blessed by its target and a repoint trips the manifest" {
  …
  ln -s /nonexistent/a "$CLAUDE_DEVC_CONFIG_DIR/claude-home/link"
  …
  ln -sfn /nonexistent/b "$CLAUDE_DEVC_CONFIG_DIR/claude-home/link"
  run check_manifest
  [ "$status" -ne 0 ]
}
```

and the deferral is logged rather than dropped:

```
# docs/working/questions.md:23
- [ ] 2026-09-03 The repo tracks `workflows/workflows` as a symlink to `/home/magfrump/claude-workflows/workflows` (mode 120000, dangling anywhere else). … · answer changes: `git rm workflows/workflows`.
```

**Evidence:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:185`, `test/cc-isolated-functions.bats:541-550`, `docs/working/questions.md:23`, `docs/reviews/execution-logs/cfc-lp4-cpr-symlink-staging-294a6c2.txt`

---

## Claim 19: "A33 Lock timeout fired the fail-closed trap and would DROP the boundary the concurrent holder had just built. ✅ Fixed — a timed-out waiter reports and stands down without forcing DROP (it changed nothing)"

**Location:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:186`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both halves — the pre-fix behavior and the post-fix behavior — as descriptions of the code at `f313de7` and `294a6c2` respectively; does not establish the row's severity grading, and does not extend to the vacuous last assertion in the corresponding bats test (see Claim 11's scope).

Pre-fix, the held-lock test asserted precisely the behavior the row describes:

```bash
# git show f313de7:test/init-firewall-rules.bats (held-lock test)
  grep -q "iptables -w 5 -P OUTPUT DROP" "$CMD_LOG"
```

Post-fix, the same test asserts its negation:

```bash
# test/init-firewall-rules.bats:953-955
  # A lock timeout must NOT tear down the boundary the holder is building.
  run grep -c -- "-P OUTPUT DROP" "$CMD_LOG"
  [ "$output" -eq 0 ]
```

The "it changed nothing" parenthetical is the property established in Claim 13.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:186`, `test/init-firewall-rules.bats:944-958`, `devcontainer-config/init-firewall.sh:275-281,380-386`

---

## Claim 20: "A34 `-C` loop asserted 5 of the load-bearing OUTPUT rules, claimed "every rule", took no `-w`, left iptables stderr unsuppressed, and sat above the "Verifying" banner. ✅ Fixed — nine rules (adds both external-resolver guards, the ipset accept, the terminal REJECT), `-w 5`, stderr quiet, comment scoped to presence only"

**Location:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:187`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five pre-fix defects and all four post-fix properties, and the arithmetic (5 + 4 = 9); does not establish that nine is the complete set (see Claim 15's scope) — the row itself does not claim completeness, having replaced the old "every rule" wording with "load-bearing".

Every pre-fix particular is confirmed by the diff: the old loop had five literals, was introduced by a comment reading "Every rule the boundary depends on must actually be present", invoked bare `iptables "${rule_args[@]}"` with no `-w` and no stderr redirection, and sat *above* the two `echo` lines it now sits below. The four additions the row enumerates — `-C OUTPUT -p udp --dport 53 ! -d 127.0.0.1 -j CC_DNS_GUARD`, its tcp twin, `-C OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT`, and `-C OUTPUT -j REJECT --reject-with icmp-admin-prohibited` — are exactly the four new entries, giving nine. All nine byte-match their install sites (Claim 15's log), `-w 5` and `2>/dev/null` are present at `:1074`, and the comment now says "presence only".

**Evidence:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:187`, `devcontainer-config/init-firewall.sh:1056-1078`, `docs/reviews/execution-logs/cfc-lp4-rule-literals-294a6c2.txt`

---

## Claim 21: "A35 `CC_EGRESS_OWNER_CHECK` undeclared and `-n`-truthy; baked path literal duplicated at two sites. ✅ Fixed — `EGRESS_DIR_DEFAULT` constant; `= "1"`; annotated as a test-only opt-in"

**Location:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:188`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two-site duplication claim as scoped to *executable* occurrences of the literal and all three fixes; does not establish that the literal is gone from the file entirely — it survives once more, in a comment at `:7` ("baked into the image at /usr/local/share/cc-egress/"), which is prose about the image path rather than a second source of truth for the check.

At `f313de7` the literal appeared at two executable sites, `:40` (the `EGRESS_DIR` default) and `:311` (the ownership guard's left comparand), quoted in Claims 9 and 10. At `294a6c2` both derive from one constant (`:44-45`, `:323`). `CC_EGRESS_OWNER_CHECK` now compares `= "1"` instead of `-n` and carries the six-line annotation at `:317-322`.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:188`, `devcontainer-config/init-firewall.sh:7,44-45,314-323`

---

## Claim 22: "420/420 bats, 13/13 python, shellcheck clean."

**Location:** commit message of `294a6c2` (Notes line)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three suites at HEAD in this sandbox, at the counts stated; does not establish that they pass in the maintainer's environment or in CI, nor that the suites cover the changed behavior adequately (that is a test-strategy question, not a fact-check one).

Executed at `/workspace`, HEAD `294a6c2`, 2026-09-03T19:49–19:51 -07:00:

- `LC_ALL=C bats test/` → plan `1..420`, 420 `ok`, 0 `not ok`, `BATS_EXIT=0`
- `python3 test/test_cc_sni_proxy.py` → `Ran 13 tests in 0.128s / OK`, `PY_EXIT=0`
- `shellcheck` on `cc-isolated.sh`, `init-firewall.sh`, `link-claude-home.sh` and `install.sh` → no output, `exit=0` for each (the commit says "the three scripts"; the fourth was run for good measure and is also clean)

**Evidence:** `docs/reviews/execution-logs/cfc-lp4-bats-294a6c2.txt`, `docs/reviews/execution-logs/cfc-lp4-python-294a6c2.txt`, `docs/reviews/execution-logs/cfc-lp4-shellcheck-294a6c2.txt`

---

## Claim 23: "enforcement_files() no longer dies before the claude-home walk when projects/ is empty … symlinks in the payload are hashed by target text so a repoint trips the manifest; compute_manifest refuses an empty list. A timed-out lock waiter no longer forces DROP over the holder's boundary. The completion check asserts nine load-bearing rules with -w 5, quiet stderr, under the Verifying banner, and says "presence only". EGRESS_DIR_DEFAULT constant; CC_EGRESS_OWNER_CHECK declared as a test-only opt-in. Bless prints an entry count; the guide states the two-label rule."

**Location:** commit message of `294a6c2` (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the nine assertions in the body paragraph, all of which are re-statements of Claims 1–16 and are individually confirmed above; does not establish the Notes line's characterisation of the pass-4 critic findings ("Pass 4 had no Structural and security all Low; the Breaking item was in my own pass-3 manifest change"), which is a summary of the four `*-r4.md` critic reports rather than a claim about this code.

Point by point: the empty-`projects/` walk (Claim 2, executed); symlink-by-target-text and repoint (Claims 3, 5b, executed); empty-list refusal (Claim 4, executed); the lock waiter (Claims 11, 13); nine rules with `-w 5`, quiet stderr, under the banner, "presence only" (Claim 15, executed); `EGRESS_DIR_DEFAULT` and the opt-in annotation (Claims 9, 10); bless entry count (Claim 7, executed); guide two-label rule (Claim 16, executed). The body's closing note — "One new question: the tracked dangling symlink workflows/workflows" — matches the single line the commit appends to the questions doc at `docs/working/questions.md:23` (quoted in Claim 18).

**Evidence:** all claims above; `docs/working/questions.md:23`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 12** (`devcontainer-config/init-firewall.sh:367-368`): "Taken after the trap, so a lock failure ends at DROP like any other abort" — **comment-only**, no behavioral defect. The same commit's `LOCK_TIMED_OUT` early-return makes a lock timeout the one abort that does *not* end at DROP. Suggested precise wording: "Taken after the trap, so a lock failure still runs the trap — which recognises this one abort (`LOCK_TIMED_OUT`) and stands down rather than forcing DROP over the holder's work."

### Mostly Accurate
- **Claim 5a** (`devcontainer-config/cc-isolated.sh:97-98`): "One sha256sum for the whole list" now describes the regular-file branch only; the symlink branch added immediately below forks `sha256sum` + `cut` (plus two command substitutions) per link. Tighten to "one `sha256sum` for the whole regular-file list … symlinks still cost a fork each, and there are few of them."

### Unverifiable
- **Claim 17b** (`docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md:184`): the "103 hashed lines" figure needs the maintainer's installed `~/.config/claude-devcontainer/claude-home/`, which does not exist in this sandbox; recomputing from the repo would measure today's tree, not the reviewed state. The "0" half and the direction of the finding are confirmed.

### Also noted (not a claim verdict)
- `test/init-firewall-rules.bats:956` — `[[ "$output" != *"fails CLOSED"* ]]` inspects `$output` from the preceding `run grep -c`, whose value is `0`, so that assertion can never fail. The `-P OUTPUT DROP` count check two lines above it is the real guard and does hold; the vacuous line is redundant rather than harmful. Recorded here because Claim 11's verification leaned on that test.
