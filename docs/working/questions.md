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
| `you: walkthrough` | A hands-on walkthrough or playtest only you can do. |
| `you: fyi` | A quick read to acknowledge, answered `seen`. |

Agent work is on the roadmap (`docs/roadmap.md`), and conditions the cycle is watching are in `docs/working/watching.md`.

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-084](#q-084--q076-live-checks) | you: terminal | One check is left: does a cc-isolated session that leaves a git worktree behind exit cleanly, with one `not... | 2026-09-27 |
| [Q-255](#q-255--herald-egress-fix-unconfirmed) | you: terminal | Did the 2026-10-28 egress fix (Q-214) stop herald's `dl.google.com` build failures? One file copy on the ho... | 2026-11-05 |
<!-- index:end -->

## Open

### Q-255 · herald-egress-fix-unconfirmed
**Needs:** you: terminal · **Opened:** 2026-11-05 · **Status:** OPEN

Did the 2026-10-28 egress fix (Q-214) stop herald's `dl.google.com` build failures? One file copy on the host and one message to the herald agent answer it.

**If you say no:** whether the fix works stays unknown. Herald's agent keeps its memory note that `dl.google.com` refuses TLS, and `android.txt` keeps saying NOT YET PROBED. If the fix did not work, herald's builds keep failing as before (65% of probe rounds failed before the fix).

- **Done so far:** the other half passed on 2026-11-07: `plugins-artifacts.gradle.org`, the name added with the fix, can't be used to reach other sites (all four probes returned 403). Full record: `docs/working/history-terminal-entries-2026-11-18.md`.
- **Read:** `docs/working/feedback/belegarth-herald.md` (the handoff) · `docs/decisions/039-pin-resolver-to-phase-a.md`

**1. On the host, outside any container.** Copies one script into your herald checkout; nothing else changes:

```
cp /home/magfrump/claude-workflows/docs/working/feedback/herald-probe.sh /home/magfrump/belegarth-herald/probe.sh
```

**2. In a herald session** (start it as you normally do), give the agent this message. It takes about 35 minutes:

```
Run these three checks and write all of their output to egress-check.txt in the repo root. Do not fix anything you find.
1. bash probe.sh "$(mktemp -d)" 1800 20   (about 30 minutes: run it in the background and wait for it). Then print the summary.txt it names, and the number printed by grep -c 'FAIL sni=dl.google.com' on the proxy-window.log in the same directory.
2. grep -c host-record /etc/dnsmasq.d/cc-allowlist.conf
3. ./gradlew :app:assembleDebug --refresh-dependencies   (the last 30 lines of its output are enough)
If check 1 counts 0 and the build finishes, retire the "dl.google.com refused TLS" note in your memory (sandbox-android-build): the cause was a stale address list in the firewall, fixed in the 2026-10-28 release.
```

**Pass:** check 1 counts 0 and the build finishes. **Send back:** `Q-255:` and the contents of `egress-check.txt`. Then `probe.sh` and `egress-check.txt` can be deleted from herald.

`probe.sh` is the script herald's agent wrote on 2026-10-17 to measure the failures: every 20 seconds it sends a HEAD request to each allowed name and records what DNS answered, then lists the addresses the firewall refused. It downloads nothing and writes only to the directory it is given.

- **Interim:** the name stays on the allowlist and `android.txt` still says NOT YET PROBED. Editing that comment changes the blessed hash and forces a re-bless, so it waits for this result and goes out with the next release.
- **If the answer differs:** a `FAIL sni=dl.google.com` for an address that is not pinned is decision 039's revisit trigger; a failed build gets a follow-up fix.

### Q-084 · q076-live-checks
**Needs:** you: terminal · **Opened:** 2026-09-27 · **Status:** OPEN

One check is left: does a cc-isolated session that leaves a git worktree behind exit cleanly, with one `note:` line and no WARNING?

**If you say no:** the exit scan's worktree rule (Q-094 [1]) stays tested only by bats, and its commits keep `Live-verified: no`. Nothing breaks: if the rule is wrong, a session that leaves a worktree behind prints the WARNING it printed before the rule.

- **Done so far:** every other step passed between 2026-09-28 and 2026-09-30 (host git version, clean exit, refusal while a session runs, push, `parallel` in the image). Full record: `docs/working/history-terminal-entries-2026-11-18.md`.

**1. On the host, outside any container.** Makes a throwaway repo, opens a session in it, and deletes the repo when the session ends:

```
T="$(mktemp -d)" && git init -q "$T/proj" && cd "$T/proj" && git -c user.name=p -c user.email=p@p commit -q --allow-empty -m init && cc-isolated "$T/proj"; echo "cc-isolated exit=$?   (expect 0)"; cd "$HOME" && rm -rf "$T"
```

**2. Inside that session**, at Claude's prompt, type this line, then exit the session with `/exit`:

```
! git worktree add -q .claude/worktrees/probe
```

**Pass:** after the session closes, the host prints a line starting `note: exit scan: only linked worktrees in git's standard layout changed`, then `cc-isolated exit=0`, and no WARNING. **Send back:** `Q-084:` and the lines from `note:` (or `WARNING`) to `cc-isolated exit=`.

- **Interim:** the Q-094 commits keep `Live-verified: no`; the rule rests on bats.
- **If the answer differs:** a WARNING or `exit=3` means the rule misses a layout git really writes, and the WARNING's lines become a fix.
