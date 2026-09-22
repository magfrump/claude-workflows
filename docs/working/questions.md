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
| [Q-023](#q-023--health-check-bats-scope) | you: judgment | Should `health-check.sh` gate 5 run all bats suites, not just `test/skills/` and `test/hooks/`? | 2026-09-18 |
| [Q-011](#q-011--mathlib-cache-host) | you: terminal | What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.) | 2026-09-12 |
| [Q-045](#q-045--sni-proxy-domain-fronting) | you: terminal | The SNI proxy checks only the ClientHello SNI and splices the encrypted stream, so a client can send an all... | 2026-09-18 |
<!-- index:end -->

## Open

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

### Q-023 · health-check-bats-scope
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

Should `health-check.sh` gate 5 run all bats suites, not just `test/skills/` and `test/hooks/`?

- **Why it's yours:** trades health-check runtime against coverage. A green health-check says nothing about 40 suites, including `link-claude-home-wiring.bats`, which a health-check comment claims hard-gates the wiring invariants.
- **Read:** `scripts/health-check.sh:336` (`check_bats`), `scripts/run-tests.sh --fast|--slow|--all`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Call `run-tests.sh --fast`** | Gate covers every `@category fast` suite | health-check slows by the fast-suite time | A slow-only regression still slips past |
| **[2] Call `run-tests.sh --all`** | Gate covers everything | health-check takes several minutes | You stop running it because it's slow |
| **[3] Leave it** | Only fix the misleading comment | none | A red suite sits unnoticed, as the format suites did until 2026-09-18 |

- **Interim:** unchanged; the full suite was run by hand in the 2026-09-18 improvement run.
- **Update (third 2026-09-18 run):** before ca04b98, `run-tests.sh` silently skipped untagged suites, and `link-claude-home-wiring.bats` was one of them, so [2] did not actually cover it. Both untagged suites are now tagged, and an untagged suite fails the runner. [2] now means what it says.

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

