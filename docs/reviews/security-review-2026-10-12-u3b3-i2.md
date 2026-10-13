Commit: 5d175c0e

# Security Review — feat/build-loop-u3b3 (iteration 2 of 3)

**Scope:** branch diff `main...5d175c0e` (docs/reviews/ excluded): `test/lib/d6-snippet.bash`, `scripts/lib/dev-cycle-read.sh` (git_harden), `scripts/dev-cycle.sh`, `scripts/build-loop.sh`, the plan's U3b3 as-built note, and the new tests
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b3-i2.md` (Stage 1, k=1); the shared brief u3b3-brief-i2.md (agent tag `sec3`)
**Reviewer:** security-reviewer (sec3), re-run of the interrupted sec2 pass. git 2.39.5, bash 5.2.15, perl 5.36, uid 1000.

No HALT escalation: none of the five escalation patterns matches.

## Trust Boundary Map

```
B1 (new):   [refs/heads/main + uid-writable object store (loose, packs, alternates)] → [snippet: replace/grafts/branch refusals, cat-file --batch re-hash, hash-object of the 4 blobs] → [main's scripts run as the gate / digest]
B2 (new):   [object-store state that steers the mode (root commit reachable, .git/shallow)] → [snippet root check, rev-list --max-parents=0 == D6_ROOT] → [choice: main's copy vs the /opt image copy]
B3 (new):   [/opt/claude-workflows image copy] → [own(): every path from scripts/lib up to / is not a symlink, uid 0, not -w] → [image copy run as the gate / digest]
B4 (moved): [repo .git/config, ~/.gitconfig, system gitconfig] → [lib git_harden: HARDEN pairs, GIT_CONFIG_GLOBAL=/dev/null, GIT_CONFIG_NOSYSTEM, ...] → [every git read in build-loop.sh, dev-cycle.sh, questions.sh]
B5:         [orchestrator environment (PATH, TMPDIR, GIT_* it sets, the cwd's .git discovery)] → [trusted by the lib header's trust model] → [snippet and the scripts it runs]
```

Input sources:

```
S1: refs/heads/main, refs/replace, the worktree's .git gitfile — runtime-mutable (any same-uid loop) — UNTRUSTED for exec sinks (which bytes run)
S2: object store: loose objects, packs + .idx, alternates, shallow — runtime-mutable — UNTRUSTED for exec sinks and for the mode selector
S3: repo / global / system git config — runtime-mutable — UNTRUSTED for exec (hooks, fsmonitor, gpg.program) and for read semantics
S4: /opt/claude-workflows/scripts/* — deploy-time, root-owned — trusted for exec once own() holds
S5: orchestrator env (PATH, TMPDIR, PERL5LIB, GIT_CONFIG_COUNT pairs) — trusted per the lib header (likelihood note: ~/.zshrc is uid-writable, rows 281/704)
S6: D6_ROOT, D6_OPT, HARDEN, F — code-constants — trusted
```

What enters from outside: the commit refs/heads/main names and the bytes the object store returns for it (S1, S2), which choose both the mode (B2) and the bytes run (B1); in the image mode, S4 behind an ownership check. The diff's central assumption is that hashing main's objects once, in one `cat-file --batch` process, vouches for what separate `rev-list`, `rev-parse` and `ls-tree` processes read; that assumption fails when one id has two stored copies (Finding 1).

## Findings

#### 1. The re-hash and the reads that pick the bytes can take different copies of the same id: a second pack runs planted bytes as main's gate (i1 A1 re-fires)

**Severity:** High
**Location:** `test/lib/d6-snippet.bash:48`, `:53-55`, `:61`, `:64`
**Boundary:** B1
**Move:** 11 (bypass enumeration), 4 (check vs use in different processes)
**Confidence:** High (executed on git 2.39.5; which copy each process takes is git's pack-search order, so other versions may differ)
**Legibility-target:** for-author

**Evidence:** `{ g rev-list --first-parent "$sha" && g rev-parse "$sha^{tree}" "$sha:scripts" "$sha:scripts/lib"; } | g cat-file --batch \` (`:53`), followed later, in separate processes, by `x="$(g ls-tree --format='%(objectmode) %(objecttype) %(objectname)' "$sha" -- "scripts/$f")"` (`:61`).

The re-hash proves that the bytes *the batch process* read for each id hash to that id. The ids it checks, and the blob ids the snippet then extracts, come from other processes (`rev-list`, `rev-parse`, `ls-tree`) that read the same ids independently. When the store holds two copies of one id (two packs, or a pack in an alternate), git picks a copy per process by its pack-search order, which moves as objects are found, so the batch process and a fresh `ls-tree` can resolve the same tree id to different bytes. Probe (sec3 P1, `/tmp/u3b3-sec3-XXXX`, removed): with every real object in an older pack and a newer pack whose index lists a forged `scripts/` tree under the real tree's id, the batch re-hash printed "ok" for all six objects, `ls-tree` named the planted blob, and the snippet ran it (`PLANTED-RAN`, exit 0, no `refuse d6:` line). The blob's `hash-object` check passes because the planted blob hashes to the id the forged tree names. Precondition: a same-uid writer plants a pack in `.git/objects/pack/` (or an alternate) before the run; no race is involved, so this is not row 509's racer class. Impact: the orchestrator runs loop-chosen bytes as the gate (`--merge` included), which is the consequence i1 A1 was filed Must Fix for; build-loop.sh closed the same class for its own reads with store_check's second-copy listing (U3a1 i1 security F1, i2 F1), which the snippet does not reuse. The same root cause undercuts the fact-check's Claim 36 reasoning ("each parent id comes from an already-hashed commit"): rev-list's parent ids come from rev-list's own copy, not the batch's. Fact-check P2/P3 tested a loose second copy beside a packed one, which both processes ignore; it did not test two packs.

**Recommendation:** Decide from the bytes that were hashed, not from a second reader: have the perl pass walk the first-parent chain itself (each commit's `parent` line from its hashed bytes, starting at `sha`) and parse the three hashed trees to find the four blob ids, then extract those blobs (whose post-extraction `hash-object` check already binds them). Alternatively refuse any id with a second stored copy, as build-loop.sh's store_check does (rows 644/648 already ask whether store_check moves to the lib). Add a two-pack test beside the two in-place tests.

#### 2. A failed or truncated root check silently selects the image copy instead of refusing

**Severity:** Medium
**Location:** `test/lib/d6-snippet.bash:48`, `:42-43`, `:69-72`
**Boundary:** B2
**Move:** 3 (error path), 5 (default-allow)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:** `if [[ "$(g rev-list --first-parent --max-parents=0 "$sha")" == "$D6_ROOT" ]]; then` (`:48`) with `else` → `d="$D6_OPT"` (`:69-70`).

This rules on brief question 1: yes, a failed root check should refuse. Every other read in the snippet ends in `|| no ...`; this one feeds a comparison, so a rev-list failure yields empty output and the `else` branch runs the image copy with exit 0. The snippet also refuses `info/grafts` but not `.git/shallow`, which rewrites parents the same way for this walk. Probe (sec3 P2): in a claude-workflows-shaped fixture, a `.git/shallow` naming main's tip, and separately a deleted loose root commit object, each made the snippet run the /opt copy (exit 0, no `refuse d6:` line; main's copy did not run). Preconditions: a same-uid writer deletes one object on main's first-parent history or writes `.git/shallow`. Impact: in claude-workflows the orchestrator runs the image's gate, which the plan says lags main ("The image lags main"), so gate fixes merged since the last release are absent for that run, and the orchestrator cannot tell which copy ran. The image copy is root-owned code, not loop bytes, so this is a downgrade, not code execution; the image's own state gate refuses `shallow` in gated modes if the image has that check, but `--settings`, `--status`, `--marker` and the digest run ungated. The header's Exit list and the plan note both say a failed git read refuses (fact-check Claims 7, 33).

**Recommendation:** Capture rev-list's status and refuse on failure; refuse `--git-path shallow` beside grafts; and refuse, rather than fall back, when the store holds the `D6_ROOT` object (`cat-file -e`) but main's walk does not end there, so the image fallback is reached only in repositories that never contained claude-workflows' root.

#### 3. Header and lib comments state guarantees the code does not hold

**Severity:** Low
**Location:** `test/lib/d6-snippet.bash:11-19`, `scripts/lib/dev-cycle-read.sh:346-347` (git_harden header's last sentence)
**Boundary:** B1, B4
**Move:** 2 (assumed guarantee recorded elsewhere)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `# runs no file the uid can write: in claude-workflows (main's first-parent` … `# commit into a fresh temp dir once every object that chose them hashes to its` … `# id` (`d6-snippet.bash:11-15`); `# gate refuses.` closing "What these cannot switch off, build-loop.sh's state gate refuses." (lib).

U4 will paste this header into SKILL.md, where it becomes the orchestrator's statement of what D6 guarantees. "Every object that chose them hashes to its id" is false under Finding 1; "runs no file the uid can write" omits that the bytes are those of whatever commit refs/heads/main names and whatever repository the cwd's `.git` discovers, both uid-writable (settled class, see below), and that the extracted copy sits in a uid-writable 0700 dir (row 200/509). The lib sentence holds for build-loop.sh's gated modes only; dev-cycle.sh, the other caller, runs no state gate (row 548; fact-check Claim 26). A comment-only issue, but it is the text a later reviewer will trust.

**Recommendation:** Narrow the header to what is checked: "main's bytes as refs/heads/main names them (a moved ref is Q-103's residual, F19), hash-checked into a fresh temp dir (the same-uid race on that dir is row 509's)". Fix the lib sentence to name build-loop.sh's gated modes and point at row 548.

#### 4. The re-hash is plain SHA-1 without collision detection

**Severity:** Informational
**Location:** `test/lib/d6-snippet.bash:52`, `:54`
**Boundary:** B1
**Move:** 9 (cryptographic choices)
**Confidence:** Low (flag for expert review)
**Legibility-target:** for-author

**Evidence:** `perl -MDigest::SHA=sha1_hex -e '...sha1_hex("$t $s\0$b") eq $id...'` and `# D6_ROOT is a SHA-1 id, so the repository is SHA-1.`

Brief claim 8 asks about "SHA-1 only". Against objects written honestly, swapping in different bytes under an existing id needs a second preimage, which is infeasible. A chosen-prefix collision pair is feasible for a funded attacker, but it needs one half landed on main through review first. git's own hashing (used by the blob check, `hash-object`) rejects known collision patterns, while the perl tree and commit re-hash does not. This is residual, not exploitable today; noted so the check's strength is stated rather than assumed. A SHA-256 repository never reaches this branch (fact-check Claim 36).

**Recommendation:** None required now. If Finding 1's fix moves tree parsing into perl, note in the comment that git's sha1dc detection applies only to the blob check.

## Rulings on the brief's questions

1. **Failed root check (`:48`).** Finding 2: it should refuse, and `shallow` should be refused beside grafts.
2. **Moved main ref (`:44-48`).** The settled hostile-loop class, not new for D6: **F19** (plan table: "A deliberate `git push` or a commit disguised as `answers` is not caught"), **override row 721** (Won't-Fix: "D13's check catches an honest slip ..., not a forger") and row 509's decision text ("that writer has cheaper routes (..., moving main itself)"), all under Q-103. See "Re-flagged settled decisions" R1. Only its wording in the snippet header is new (Finding 3).
3. **What the re-hash covers (brief claim 8).** Covered: the bytes the batch process reads for main's first-parent commits and the root, `scripts/` and `scripts/lib/` trees; the four blobs via `hash-object` after extraction. An in-place loose rewrite (T36's two tests) and a loose second copy beside a packed one (fact-check P2/P3) are handled. Not covered: a second *packed* copy of an id, including one in an alternate's pack (Finding 1); the bytes the separate `rev-list` (`:48`, `:53`), `rev-parse` (`:53`) and `ls-tree` (`:61`) processes parse; a writer between the re-hash and the reads (row 509 class, R2); collision resistance beyond plain SHA-1 for trees and commits (Finding 4). The order is re-hash, then ls-tree and cat-file reads, then the blob hash, then the run: correct for a single-copy store.
4. **git_harden for dev-cycle.sh; ownership checks.** dev-cycle.sh calls `git_harden` after `scrub_reexec` and the argument loop, and before its first git call (`ROOT="$(git rev-parse --show-toplevel ...)"`); questions.sh inherits the exported environment. The digest's and check modes' git commands that I read are object and index reads with no diff driver, textconv or filter path: `log` with `--format`/`--name-only`, `log -G` with `--no-textconv --no-show-signature`, `diff --name-only`, `ls-files`, `ls-tree`, `cat-file blob`, and `grep` on a tree. What git_harden leaves on is not refused for dev-cycle.sh (row 548; R3). The /opt ownership walk: cleared, see the Endorsement Claims and the bypass list.

## Untested bypass candidates

- **A second pack reached through `objects/info/alternates`** (B1). Expected to behave like Finding 1 because alternates' packs join the same pack list; not executed.
- **An image copy on a filesystem that reports uid 0 for files the uid controls** (FUSE, a user-namespace mount; B3). own() trusts `stat -c %u`; mounting at the fixed `/opt/claude-workflows` should need write access to a root-owned mountpoint, but this was not tested in this container.
- **Root on a read-only mount** (B3). own() relies on `-w` being true for root; on a read-only mount it is false (fact-check Claim 10, unverifiable without root).
- **Repository discovery** (B1/B5). A rewritten `.git` gitfile in the orchestrator's worktree points every `g` call at another repository. This is the R1 class; it was not executed.

Tested candidates: two packs (Finding 1, bypass); `.git/shallow` and a missing root object (Finding 2, downgrade); replace refs, grafts, a symbolic or tag-valued main, both main and master (T36, fact-check S1: refused); an in-place tree or commit rewrite (T36: refused); a uid-owned image copy (T37: refused).

## Endorsement Claims

- **Claim:** In the image mode, own() runs on each of the four files and on every directory from `$D6_OPT/scripts/lib` up to `/`, and each check requires no symlink, owner uid 0 and `! -w` for the running uid.
  **Location:** `test/lib/d6-snippet.bash:35`, `:71-72`
  **Evidence:** read-static
  **Verified:** read own() and the `x="${x%/*}"; x="${x:-/}"` walk; T37's uid-owned case refuses (fact-check S1, Claim 47).
  **Not verified:** a filesystem that reports uid 0 for uid-controlled files; root's `-w` on a read-only mount.
  **route: code-fact-check**
- **Claim:** dev-cycle.sh calls git_harden before its first git call, and the lib runs no git at source time.
  **Location:** `scripts/dev-cycle.sh:125-129`, `scripts/lib/dev-cycle-read.sh`
  **Evidence:** read-static (and fact-check Claim 1, executed)
  **Verified:** dev-cycle.sh lines 91-129; the lib's git calls listed by grep are all inside functions.
  **Not verified:** git calls made by a program that `scrub` (lines 127+, no `git` in its body) or perl start in the scrub_reexec parent, which runs unhardened before the child's git_harden.
  **route: code-fact-check**
- **Claim:** The snippet runs the chosen script with `DEV_CYCLE_SCRUBBED`, `BASH_ENV` and `ENV` unset, so the script's own scrub_reexec runs, and with stdin from /dev/null.
  **Location:** `test/lib/d6-snippet.bash:74`, `:79`
  **Evidence:** read-static
  **Verified:** read `:74-79` and scrub_reexec's first line, `[[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0`.
  **Not verified:** other variables in the orchestrator's environment that change bash or git behaviour (trusted by the lib header, B5).

## Primitive sweep

Primitive: process exec (which bytes run as the gate)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/lib/d6-snippet.bash:74` main mode, `bash "$d/scripts/$s"` | S1, S2 | refusals `:40-47`, re-hash `:53-55`, blob hash `:66-68` | Finding 1 (second pack), R1 (moved ref), R2 (temp-dir race) |
| `test/lib/d6-snippet.bash:74` image mode | S4, chosen by S2 | own() `:71-72` | cleared for the bytes; the selector is Finding 2 |
| `test/lib/d6-snippet.bash:54` `perl -e` | S6 (fixed program), S5 (PERL5LIB) | none needed | cleared: code-constant program; perl 5.36 does not load modules from `.` |
| `test/lib/d6-snippet.bash:34` `git` via PATH | S5 | trusted env | cleared under the trust model |
| `scripts/lib/dev-cycle-read.sh` scrub_reexec `bash "$self"` | S6 | n/a | cleared: re-runs the already-chosen script |
| git command-capable config (hooks, fsmonitor, gpg.program, textconv, filters) in dev-cycle.sh's reads | S3 | HARDEN pairs, `--no-textconv`, `--no-show-signature` | cleared for the commands read (question 4); unrefused remainder is R3 |

Primitive: file write / delete
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/lib/d6-snippet.bash:64` `cat-file blob > "$d/scripts/$f"` | S2 | fresh `mktemp -d`; F is a constant list | cleared (R2 for the race) |
| `test/lib/d6-snippet.bash:57` `trap 'rm -rf "$d"' EXIT` | S5 (TMPDIR) | set only after mktemp succeeds; never set in image mode | cleared |

## Re-flagged settled decisions

- **R1 — a moved refs/heads/main (brief question 2).** The re-hash shows main's objects are self-consistent, not that refs/heads/main names a commit the gate landed. A same-uid loop that commits on top of the real history and moves the ref passes every hash, and the snippet runs that commit's scripts, including the `--main-log` that would report the move. Settled as **F19 / override row 721** (Won't-Fix: --main-log catches honest slips, not forgers) and row 509's decision ("moving main itself"), under Q-103. Variants of the same class, also not new: rewriting the orchestrator worktree's `.git` gitfile (repository discovery, B5), and, in another project, building a history whose first-parent root is claude-workflows' `640cf007` (whose object the uid can copy) so the snippet takes main mode instead of the image. Each needs a loop that writes refs or `.git` state, the F19 capability. The only new item is the header's wording (Finding 3).
- **R2 — the extracted copy in a uid-writable 0700 temp dir** between the hash check and the run, and while the script sources its lib: **rows 200 and 509** (Q-103 residual), as the plan note and d9515d09 already say.
- **R3 — dev-cycle.sh runs no state_gate or default_gate:** **row 548**. Under D6 the snippet extracts from refs/heads/main while dev-cycle.sh's resolve_main may follow origin/HEAD, and nothing refuses what git_harden leaves on for the digest. Settled; only the lib comment (Finding 3) is new.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Re-hash and ls-tree/rev-list read different copies of one id; a second pack runs planted bytes (A1 re-fires) | High | B1 | `test/lib/d6-snippet.bash:48,53-55,61,64` | High |
| 2 | A failed root check, or `.git/shallow`, silently selects the (lagging) image copy | Medium | B2 | `test/lib/d6-snippet.bash:42-48,69-72` | High |
| 3 | Snippet header and git_harden header overstate what is checked | Low | B1, B4 | `test/lib/d6-snippet.bash:11-19`, `scripts/lib/dev-cycle-read.sh:346-347` | High |
| 4 | Re-hash is plain SHA-1 with no collision detection (trees, commits) | Informational | B1 | `test/lib/d6-snippet.bash:52,54` | Low |

## Overall Assessment

git_harden's move into the lib and its use by dev-cycle.sh are sound for the reads examined, and the image-copy ownership walk holds for the cases read. The D6 snippet's i1 A1 fix does not hold against a second packed copy of an object: the check and the use are separate git processes that can resolve one id to different bytes, so a pre-planted pack still runs loop-chosen bytes as the gate (Finding 1, executed). This is fixable in place by deciding from the hashed bytes themselves or by reusing store_check's second-copy refusal. The root check's fail-open to the image copy (Finding 2) is a smaller in-place fix. The single most important thing to address is Finding 1, since it is the A1 consequence the previous iteration was blocked on. Not safe to merge as is; the other endorsement claims are pending execution verification.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/security-review-2026-10-12-u3b3-i2.md, structured per the security-reviewer skill.
- Answered: yes. All four brief questions are ruled on above. Two probes were executed (sec3 P1 two packs, P2 root selector) in `/tmp/u3b3-sec3-XXXX` dirs, each removed on exit; no processes left running. The bats suite was not re-run; I relied on the fact-check's S1 (19/19).
- Out of scope: performance of a perl-side walk for Finding 1's fix; the U4 SKILL.md byte-equality half (pending by design).
- Escalate: Finding 1 (High) re-opens i1 A1. The fix choice (parse the hashed bytes vs reuse store_check, rows 644/648) is the author's. Whether the second-pack route matters, given that F19's moved-ref route is accepted, is the user's Q-103 call; i1 treated A1 as Must Fix regardless.
- Decisions I made: I reused the sec2 probe scripts (prefix changed to sec3, python run with `-I`) and re-executed them rather than trusting the earlier logs. I rated Finding 2 Medium under the floor rule, although it runs root-owned rather than loop-written bytes. I filed the cross-repo D6_ROOT history and the gitfile redirect under R1, not as new findings, because both need the F19 capability.
