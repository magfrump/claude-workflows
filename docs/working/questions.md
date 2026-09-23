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
| [Q-051](#q-051--lean-fronting-entries) | you: judgment | Two `lean` names front to tenants nobody listed (Q-045): `elan.lean-lang.org` reaches any GitHub Pages site... | 2026-09-23 |
| [Q-052](#q-052--android-google-fronting) | you: judgment | `dl.google.com` and `maven.google.com` front to Google-hosted tenants (Q-045: Host www.google.com got Googl... | 2026-09-23 |
| [Q-049](#q-049--deny-rule-absolute-path-form) | you: terminal | Do the live deny rules match at all? `link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings... | 2026-09-21 |
| [Q-053](#q-053--azure-blob-fronting-probe) | you: terminal | Does the Azure Blob front end behind `lakecache.blob.core.windows.net` route a different storage account's ... | 2026-09-23 |
<!-- index:end -->

## Open

### Q-049 · deny-rule-absolute-path-form
**Needs:** you: terminal · **Opened:** 2026-09-21 · **Status:** OPEN

Do the live deny rules match at all? `link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings*.json)`, with one leading slash. If Claude Code reads `/path` as relative to the settings file and needs `//path` for an absolute path (which is my recollection of its docs, unverified because the sandbox has no egress), every global-dir deny rule matches nothing. `guard-trusted-writes.py` then defers to rules that aren't there, so file-tool edits to global settings, hooks and CLAUDE.md get no gate. This predates this branch. The 2026-09-21 iteration-2 review raised it as N3.

- **Read:** `hooks/wiring.json` deny block, `devcontainer-config/link-claude-home.sh:137` (the `{{CLAUDE_DIR}}` substitution), `~/.claude/settings.json` (live rules)
- **2026-09-23 run: INCONCLUSIVE.** Every line read `Ignoring 1 permissions.allow entry from .claude/settings.json: this workspace has not been trusted`. A project `.claude/settings.json` in a fresh temp dir is untrusted, so its `allow` was dropped. The error text was also merged into stdout (`2>&1`), which broke the `jq` parse. The revised paste passes the rules with `--settings <file>`, a CLI flag source that needs no workspace trust. It grants the target dir with `--add-dir` and keeps stderr separate.
- **The paste** (on the host; three tiny headless calls on your subscription):

```bash
for form in control single double; do
  d=$(mktemp -d); td=$(mktemp -d); t=$td/target.txt
  case $form in control) deny='' ;; single) deny="\"Write($t)\"" ;; double) deny="\"Write(/$t)\"" ;; esac
  printf '{"permissions":{"allow":["Write"],"deny":[%s]}}\n' "$deny" > "$d/s.json"
  out=$(cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --settings "$d/s.json" --add-dir "$td" --output-format json 2>"$d/err")
  turns=$(printf '%s' "$out" | jq -r '.num_turns // 0' 2>/dev/null); turns=${turns:-0}
  if [ -e "$t" ]; then r="file written"; elif [ "$turns" -ge 2 ]; then r="not written (claude ran $turns turns)"; else r="INCONCLUSIVE, claude did not run: $(head -c 200 "$d/err")"; fi
  echo "$form: $r"
done
```

- **Assumption this run rests on:** that a path in a `--settings` file is parsed the same way as one in `~/.claude/settings.json`. If Claude Code reads `/path` relative to the settings file, neither file sits at `/`, so the single-slash form misses in both and the result carries over.

- **How to read it:** `control` has no deny rule and must say "file written". If it doesn't, the other two lines prove nothing (the project settings weren't trusted, or Write needed a prompt), so paste the output back as is. With a good control: `single: not written` means a single leading `/` works; `single: file written` with `double: not written` means only `//` is absolute.
- **What I do with it:** if single-slash is enforced, N3 is closed as a non-issue. If only double-slash is enforced, `link-claude-home.sh` emits `//` for absolute dirs, a test pins it, and you re-install and re-bless. In either case I'd also consider having the hook return `deny` itself for HARD paths instead of deferring, since that holds whether or not the rules match.
- **Interim:** unchanged. The devcontainer's `/opt` payload is read-only, which bounds the hooks and CLAUDE.md exposure there. `~/.claude/settings*.json` is not bounded that way.

### Q-051 · lean-fronting-entries
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** OPEN

Two `lean` names front to tenants nobody listed (Q-045): `elan.lean-lang.org` reaches any GitHub Pages site, and `reservoir.lean-lang.org` reached an unrelated third-party site. Keep them or drop them?

- **Why it's yours:** Q-045 left keeping or dropping a fronting entry to your judgment on the evidence.
- **Read:** `devcontainer-config/egress/lean.txt` (the header's DOMAIN FRONTING note and each entry's comment); Q-045's table in the archive
- **What each is for:** elan is baked into the image (log #51), and toolchains come from `release.lean-lang.org`, which refuses fronting. So `elan.` serves only elan's installer and self-update [inferred from lean.txt's comments, not tested]. `reservoir.` serves only a lakefile `require` by bare package name; mathlib's dependencies are git requires that resolve through GitHub.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Drop both** | Remove both lines from `lean.txt`, then install and re-bless | One install + bless | A bare-name `require`, or an elan self-update, fails loudly in-container until the line is restored |
| **[2] Drop `elan.`, keep `reservoir.`** | Keep the index for bare-name requires, with an ACCEPTED RISK note | One install + bless | A session can reach any tenant on reservoir's hosting platform, possibly one that runs server code |
| **[3] Keep both, accept the risk** | Only the ACCEPTED RISK notes change (comments, no re-bless) | none | Two open channels stay in the lean profile |

- **Interim:** both stay listed, with the residual written beside them. The profile is opt-in (`--profile lean`), so only lean sessions carry it.
- **If the answer differs:** a one-line removal per entry, then `install.sh` and a re-bless. The live-verify gate will ask for a trailer, because removing a line is a non-comment change.

### Q-052 · android-google-fronting
**Needs:** you: judgment · **Opened:** 2026-09-23 · **Status:** OPEN

`dl.google.com` and `maven.google.com` front to Google-hosted tenants (Q-045: Host www.google.com got Google's home page), which probably includes writable `storage.googleapis.com`. Both are Google's Maven host (`google()`), which Android builds need. Accept the residual, or drop Google Maven from the profile?

- **Why it's yours:** it trades the egress threat model against a working Android profile. `android.txt` accepted "the whole GFE surface" when the firewall matched only IPs. The SNI proxy was expected to narrow that, and it does not.
- **Read:** `devcontainer-config/egress/android.txt` (ACCEPTED RISK block)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Accept and keep** | The ACCEPTED RISK note, updated today, stands | none | An android session has an outbound channel to any Google-hosted service |
| **[2] Drop both names** | `google()` artifacts must come from the Gradle cache baked in at image build | Android builds that resolve new Google artifacts fail until an image rebuild | The profile works only for projects whose Google dependencies are baked in |

- **Interim:** [1]. Only the comment changed. The profile is opt-in.
- **If the answer differs:** remove the two lines, install, re-bless (live-verify trailer).

### Q-053 · azure-blob-fronting-probe
**Needs:** you: terminal · **Opened:** 2026-09-23 · **Status:** OPEN

Does the Azure Blob front end behind `lakecache.blob.core.windows.net` route a different storage account's `Host`? Q-045's root-path probe was inconclusive because it compared two error pages. This probe compares real container listings. An attacker's own storage account with a SAS token would be a write sink, so the answer matters more here than for a read-only mirror.

- **Read:** `devcontainer-config/egress/lean.txt` (lakecache ACCEPTED RISK note); Q-045 in the archive
- **The paste** (on the host):

```bash
A=lakecache.blob.core.windows.net; B=azureopendatastorage.blob.core.windows.net
p1='/mathlib4-master?restype=container&comp=list&maxresults=1'   # lakecache's own public listing (Cache/Requests.lean:1242)
p2='/mnist?restype=container&comp=list&maxresults=1'             # a public Azure Open Datasets container
show() { curl -sS -m 10 -w ' [%{http_code}]' "$@" 2>&1 | tr -d '\n' | head -c 220; echo; }
echo "1 lakecache direct : $(show "https://$A$p1")"
echo "2 other acct direct: $(show "https://$B$p2")"
echo "3 fronted          : $(show -H "Host: $B" "https://$A$p2")"
```

- **How to read it:** line 1 must show an `<EnumerationResults` listing and `[200]`. Line 2 must as well; if it doesn't, the container name is wrong and the run proves nothing, so paste it back. If line 3 matches line 2 (a `mnist` listing), fronting works across accounts. If line 3 is an error (`ResourceNotFound`, `InvalidQueryParameterValue`, 400 or 404), the front end stays within the SNI's account.
- **What I do with it:** refuses → the lakecache ACCEPTED RISK note is confirmed as written, with the date. Fronts → a new judgment entry on keeping lakecache, which is the entry that makes the lean profile usable at all.
- **Interim:** lakecache stays listed; `lean.txt` calls it inconclusive.
