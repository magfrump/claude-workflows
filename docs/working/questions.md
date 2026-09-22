# Running questions

Questions raised during autonomous work that did not justify stopping.

**To answer:** write `Q-0NN: <your answer>` anywhere — a reply, a file, a commit.
The ID is the whole handle; you never have to restate the question. Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.

**Needs** is the route — who or what actually discharges the item, from
`docs/working/triage-2026-09-17-backlog.md` §3.1:

| Route | Meaning |
|---|---|
| `you: judgment` | Needs your taste or authority. The only real attention spend. |
| `you: terminal` | Needs your machine, not your mind. Collected into one paste below. |
| `agent` | Mechanical. Should not be here long. |
| `trigger` | Not a question yet — a condition being watched. Costs you nothing. |
| `deferred` | Scheduled behind an event that has not happened. |

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-048](#q-048--guard-cooccurrence-overblock) | you: judgment | Closing the review's bypasses of Q-035 needed a broader Bash rule, applied only to commands that contain a ... | 2026-09-21 |
| [Q-050](#q-050--guard-resolved-path-policy) | you: judgment | When a file-tool edit reaches a protected global file through its real path rather than through `~/.claude/... | 2026-09-21 |
| [Q-011](#q-011--mathlib-cache-host) | you: terminal | What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.) | 2026-09-12 |
| [Q-045](#q-045--sni-proxy-domain-fronting) | you: terminal | The SNI proxy checks only the ClientHello SNI and splices the encrypted stream, so a client can send an all... | 2026-09-18 |
| [Q-049](#q-049--deny-rule-absolute-path-form) | you: terminal | Do the live deny rules match at all? `link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings... | 2026-09-21 |
<!-- index:end -->

## Open

### Q-050 · guard-resolved-path-policy
**Needs:** you: judgment · **Opened:** 2026-09-21 · **Status:** OPEN

When a file-tool edit reaches a protected global file through its real path rather than through `~/.claude/…`, what should the guard hook do? On a bare-host install, `~/.claude/CLAUDE.md` links to your checkout's `global-instructions/CLAUDE.md`. Since a577546, Edit/Write on that checkout file is **denied**, with no approve option. Hook scripts linked one at a time get **no gate at all** at their checkout path (N12). The devcontainer is unaffected, because its targets are the read-only `/opt` payload.

- **Why it's yours:** it trades your ability to edit the global instructions in this repo on the host against how strongly the installed copy is protected.
- **Read:** `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter3.md` (R6, N12, and the iteration-4 gate at the end), `hooks/guard-trusted-writes.py:95-155`
- **Related:** Q-049. If deny rules turn out not to match, the "let the hook deny everything itself" redesign also applies.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Ask on real-path edits** | Real-path edits of protected files (the checkout CLAUDE.md and hook scripts) get an approve/deny prompt, whether or not the session is tainted. No deny rule names these paths, so the ask overrides nothing. | One prompt per edit to the global instructions or a hook in this repo | A prompt you approve by reflex |
| **[2] Deny (current branch)** | Keep a577546, document it, test it, and give hook scripts the same deny | You edit global instructions only outside Claude, or with the hook disabled | Blocks legitimate repo maintenance on the host |
| **[3] Defer, as before this branch** | No gate on real-path edits | none | A tainted session rewrites your global instructions through the checkout path |

- **Interim:** the branch holds [2]. It is not merged, so nothing on the host has changed. The review-fix loop is paused at its 3-iteration cap with decision `escalate`.
- **If the answer differs:** one change to the `hard-resolved` outcome in `classify_path`, plus tests, then a fourth review iteration that you authorize.

### Q-049 · deny-rule-absolute-path-form
**Needs:** you: terminal · **Opened:** 2026-09-21 · **Status:** OPEN

Do the live deny rules match at all? `link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings*.json)`, with one leading slash. If Claude Code reads `/path` as relative to the settings file and needs `//path` for an absolute path (which is my recollection of its docs, unverified because the sandbox has no egress), every global-dir deny rule matches nothing. `guard-trusted-writes.py` then defers to rules that aren't there, so file-tool edits to global settings, hooks and CLAUDE.md get no gate. This predates this branch. The 2026-09-21 iteration-2 review raised it as N3.

- **Read:** `hooks/wiring.json` deny block, `devcontainer-config/link-claude-home.sh:137` (the `{{CLAUDE_DIR}}` substitution), `~/.claude/settings.json` (live rules)
- **The paste** (on the host; it uses your subscription for three tiny headless calls). For each run it grants Write, denies the target (none for `control`), asks Claude to write it, and reports whether the file appeared:

```bash
for form in control single double; do
  d=$(mktemp -d); t=$(mktemp -d)/target.txt; mkdir -p "$d/.claude"
  case $form in control) deny='' ;; single) deny="\"Write($t)\"" ;; double) deny="\"Write(/$t)\"" ;; esac
  printf '{"permissions":{"allow":["Write"],"deny":[%s]}}\n' "$deny" > "$d/.claude/settings.json"
  out=$(cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --output-format json 2>&1)
  turns=$(printf '%s' "$out" | jq -r '.num_turns // 0' 2>/dev/null); turns=${turns:-0}
  if [ -e "$t" ]; then r="file written"; elif [ "$turns" -ge 2 ]; then r="not written (claude ran $turns turns)"; else r="INCONCLUSIVE, claude did not run: $(printf '%s' "$out" | head -c 150)"; fi
  echo "$form: $r"
done
```

- **How to read it:** `control` has no deny rule and must say "file written". If it doesn't, the other two lines prove nothing (the project settings weren't trusted, or Write needed a prompt), so paste the output back as is. With a good control: `single: not written` means a single leading `/` works; `single: file written` with `double: not written` means only `//` is absolute.
- **What I do with it:** if single-slash is enforced, N3 is closed as a non-issue. If only double-slash is enforced, `link-claude-home.sh` emits `//` for absolute dirs, a test pins it, and you re-install and re-bless. In either case I'd also consider having the hook return `deny` itself for HARD paths instead of deferring, since that holds whether or not the rules match.
- **Interim:** unchanged. The devcontainer's `/opt` payload is read-only, which bounds the hooks and CLAUDE.md exposure there. `~/.claude/settings*.json` is not bounded that way.

### Q-048 · guard-cooccurrence-overblock
**Needs:** you: judgment · **Opened:** 2026-09-21 · **Status:** OPEN

Closing the review's bypasses of Q-035 needed a broader Bash rule, applied only to commands that contain a write (`>`, `tee`, `cp`, `mv`, `install`, an inline interpreter…). The literal fragments `.claude/hooks`, `.claude/settings`, `.claude/CLAUDE.md` and `managed-settings` are denied on their own. Beyond those: if the command names `CLAUDE.md`, it is denied when it also contains, anywhere, `~`, `$HOME`/`${HOME…}`, the home path, `.claude`, `global-instructions` or the config dir. If it names `settings*.json` or `hooks`, it is denied when it also contains `.claude`, `CLAUDE_CONFIG_DIR` or the literal config dir. False denies: a heredoc that writes a message file mentioning `CLAUDE.md` next to `HEAD~1`, and any Bash write into an agent worktree's `hooks/` (`/workspace/.claude/wt-*/hooks/…`). Keep it, or narrow it?

- **Why it's yours:** Q-035 asked to reconsider if the over-block got annoying. This trades catching disguised global writes for false denies.
- **Read:** `hooks/guard-trusted-writes.py` (c5a7c96), `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20.md` R1/A10

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep the co-occurrence rule** | Any indicator anywhere in the command → deny | Agents route those edits through Edit/Write and `git commit -F` | Occasional false denies in worktrees and commit messages |
| **[2] Exempt `.claude/wt-*` and `.claude/worktrees/`** | Worktree paths don't count as the `.claude` indicator | none | A worktree path used to smuggle a global write is missed |
| **[3] Narrow to path-position matches** | Only an indicator in the same shell word as the target counts | none | `H=~; … $H/CLAUDE.md`-style indirection gets through again |

- **Interim:** [1]. It is the fail-closed choice, and only takes effect once the hook is redeployed.
- **If the answer differs:** edit `_HOME_INDICATORS` / `_CFG_INDICATORS` and add tests for the exempted shape.

### Q-011 · mathlib-cache-host
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** OPEN

What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.)

- **Attempt 2026-09-17 — your run was against the right file, and the answer is that the question's shape is wrong.** `rg -o 'https://[^"]*' .../mathlib/Cache/Requests.lean` returned exactly two strings: a bare `https://` and `https://github.com/leanprover-community/mathlib4.git`. A bare prefix means the cache URL is **assembled at runtime**, not written down as a constant — which is also what your sketched docstring describes (`MATHLIB_CACHE_GET_URL` → `--cache-from` → `MATHLIB_CACHE_FROM` → `defaultContainersForRepo repo`). So there may be no single hostname to list: the host comes from a per-repo container list, and an allowlist entry has to name whatever `defaultContainersForRepo` resolves to for mathlib4.
- **Attempt 2026-09-18: half answered, and the entry stays open.** Your paste (`docs/human-author/answers-9-18-26.txt`) settles which *kind* of host it is. `Cache/Marker.lean:34` builds URLs as `s!"{container.azureURL}/m/{normalizeRepo repo}/{sha}"`, so every container is an **Azure Blob** endpoint, not ghcr.io or another registry, and the registry branch of "What I do with it" is ruled out. It does not show the storage-account hostname. `head -60` cut the output off before the definitions of `defaultContainersForRepo` and `azureURL`, where that literal lives. I could guess `lakecache` from the old code, but the VERIFY comment asks for the name to be *seen*, so I am not closing on a guess. Also worth checking: "widens the lookup chain" suggests several containers. An Azure container is a path under one account, so they probably share one host. If they span accounts, the allowlist needs each account.
- **Read:** `devcontainer-config/egress/lean.txt` (the `lakecache.blob.core.windows.net` entry and its ACCEPTED RISK note)
- **The paste**, narrowed to the one missing literal:

```bash
M=verifier/lean-project/.lake/packages/mathlib     # any mathlib4 checkout works
rg -n 'blob\.core\.windows\.net|azureURL|def defaultContainersForRepo' -A6 "$M"/Cache/*.lean
```

- **What I do with it:** if every hostname it prints is `lakecache.blob.core.windows.net`, the VERIFY comment is discharged and the entry stays as it is. If it prints another account, `egress/lean.txt` swaps to it (or lists each one). The ACCEPTED RISK note holds either way, since every candidate is Azure Blob.
- **Interim:** `lakecache.blob.core.windows.net` stays listed, carrying its VERIFY comment. A wrong entry degrades to "stays blocked", never to a wider allowlist, so the cost of being wrong is a slow first build rather than an exposure.
- **If the answer differs:** correct `egress/lean.txt`, re-install, re-bless.

### Q-045 · sni-proxy-domain-fronting
**Needs:** you: terminal · **Opened:** 2026-09-18 · **Status:** OPEN

The SNI proxy checks only the ClientHello SNI and splices the encrypted stream, so a client can send an allowlisted SNI with a different HTTP `Host` and reach another tenant on a CDN that routes by Host. The docs say exact-name entries have "no such residual". Accept and document it, or test the front ends first?

- **Why it's yours:** it is the egress-confinement threat model; closing it would need TLS interception, which the design rules out.
- **Read:** `devcontainer-config/cc-sni-proxy.py:19-29`; the SNI PROXY block's RESIDUAL text in `devcontainer-config/init-firewall.sh`. Reasoning only: the sandbox has no egress to test any CDN.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Document the residual** | Correct the "no such residual" claim and name domain fronting | none | The android/lean profiles may allow fronting to arbitrary tenants |
| **[2] Test first, then decide on the profiles** | Run `curl --connect-to` with a mismatched Host through the android and lean front ends on the host | ~10 min at your terminal | none — the answer then decides whether those entries stay |

- **Interim:** unchanged; the docs still over-claim.
- **Answered 2026-09-20: [2], test first.** Rerouted to `you: terminal`. Run this on the **host** (the sandbox has no egress). For each allowlisted android/lean name it sends that name as SNI with the `Host` header of a tenant on a large CDN, and prints the fronted response next to the tenant's own response. **Fronting works for a pair when the two lines carry the same title** (or the same non-error status and server). A 421, 403, 404 or a different title means the front end refuses. Paste the whole output back.

```bash
b=$(mktemp); probe() { r=$(curl -sS -m 10 -o "$b" -w '%{http_code} %header{server}' "$@" 2>&1); t=$(grep -o -i -m1 '<title>[^<]*' "$b" | head -c 50); echo "$r $t"; }
for sni in dl.google.com maven.google.com repo.maven.apache.org repo1.maven.org services.gradle.org plugins.gradle.org elan.lean-lang.org release.lean-lang.org releases.lean-lang.org reservoir.lean-lang.org lakecache.blob.core.windows.net; do
  for tgt in www.google.com www.python.org www.cloudflare.com github.com azureopendatastorage.blob.core.windows.net; do
    printf '%-32s Host:%-44s fronted=[%s] direct=[%s]\n' "$sni" "$tgt" "$(probe -H "Host: $tgt" "https://$sni/")" "$(probe "https://$tgt/")"
  done
done; rm -f "$b"
```

- **What I do with it:** every front end refuses → the docs name domain fronting as a residual that the tested profiles do not carry (with the test date). Any pair succeeds → that profile's entry gets an ACCEPTED RISK note or is removed, which is your call on the evidence, and the "no such residual" line is corrected either way.

