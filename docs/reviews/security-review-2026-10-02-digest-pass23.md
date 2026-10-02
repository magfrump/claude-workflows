Commit: ba39470 (A) / 36ca12c (B)

# Security Review — dev-cycle pass 23 (pass-22 fix round: check modes, skill wiring)

**Scope:** A: `git diff bc98571..ba39470 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest). B: `git diff 6c8ae91..36ca12c -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` (wt-devcycle; merge f2843cd, whose `scripts/dev-cycle.sh` is identical to ba39470's)
**Date:** 2026-10-02
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass22.md` (pass 22's k=1 fact-check). It covers the code before this delta, so the new modes' claims are not independently fact-checked; I did not re-verify anything it verified.

All probes ran as single `set -eu` scripts in `mktemp -d -p .../scratchpad/sec23` dirs with the `$PWD` guard, against `/workspace/.claude/wt-digest/scripts/dev-cycle.sh`. Both worktrees were clean before and after. No dev-cycle process was left running. `bats test/scripts/dev-cycle.bats`: 33/33 ok (run from a temp dir, `TMPDIR` pointed at it). awk here is mawk 1.3.4. gawk and BWK awk are not installed, so they were not tested.

## Trust Boundary Map

```
B1 (new):   [questions.md / questions-archive.md text, many writers] → [check_answer: ID shape + ANSWER_AWK] → [keep/drop/open applied to a brief]
B2 (moved): [brief's branch line, repo text]                          → [check_branch: form + check-ref-format + show-ref --verify] → [hash given to git ancestry/rev-list]
B3 (new):   [fix target path named by repo text / agent judgment]     → [check_fix: pathform + ^docs/|^README.md$ + check_path] → [agent file edit, landed via pr-prep]
B4 (moved): [refs/remotes/origin/HEAD, refs/heads/{main,master}]      → [show-ref --verify --hash + ^{commit}] → [MAIN_SHA to git log]
B5 (moved): [docs/working/briefs/ listing]                            → [--check-path 'docs/working/briefs/*.md'] → [brief reads, open count, branch skip list]
```

```
S1: questions files' entry text   — runtime-mutable (any session, any merge) — UNTRUSTED for the keep/drop decision sink; trusted for nothing beyond display
S2: Q-NNN ID from a brief's Asked:/Applied: — runtime-mutable — UNTRUSTED (shape-checked ^Q-[0-9]+$ before awk -v)
S3: branch name in a brief        — runtime-mutable — UNTRUSTED for git argv; the hash from show-ref is the trusted derivative
S4: path for an in-cycle fix      — runtime-mutable (from commit messages, plans, entries) — UNTRUSTED for the write sink
S5: local refs (refs/heads/*, symbolic refs) — host-local, not repo text — trusted (a change needs host control)
S6: origin/HEAD target name       — remote-controlled — UNTRUSTED for argv; only used inside refs/heads/<c> after a leading-dash skip
```

Repo text now reaches four sinks only through check modes: answers (B1), branch hashes (B2), fix targets (B3) and brief listing (B5). The branch and default-branch paths hold under every probe I ran. The weaker spots are (a) B1 accepting any `### Q-NNN` line in either file as the entry, and (b) B3's scope being a directory rule, which admits non-documentation and gitignored files.

## Findings

#### 1. `--check-fix` admits scripts, user-authored records and gitignored state files under `docs/`, and its own comment says those are filed

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:246-253` (A); `skills/dev-cycle/SKILL.md:71-74` (B)
**Boundary:** B3
**Move:** 11 (bypass enumeration), 1 (per-consequence trust)
**Confidence:** High for the mechanism (executed). Medium that a cycle acts on it.
**Legibility-target:** the cycle agent, which sees `ok` and treats the path as an approved fix target; and the user reviewing the cycle branch, who never sees an edit to an ignored file.

**Evidence** (verbatim, the whole function):
```
# An in-cycle fix edits documentation only: anything else (scripts, hooks,
# egress lists, instruction files) is filed, never changed by the cycle itself.
check_fix() {
  local a="$1"
  if ! pathform "$a" || [[ "$a" == *[*?]* ]]; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif [[ ! "$a" =~ ^docs/|^README\.md$ ]]; then echo "skip $a: in-cycle fixes edit only docs/ and README.md; file it instead"
  else check_path "$a"; fi
}
```
Probe (p3b), in a repo where `docs/working/*.json` is gitignored:
```
ok docs/reviews/x.sh
ok docs/working/scratch/h.py
ok docs/working/round-history.json
```
The real tree has the same classes. Tracked: `docs/reviews/execution-logs/acr-299727c-probes.sh`, `…/2026-09-23-r3-guard-probe.py`, `docs/working/scratch/health-check.py`, `docs/human-author/prompts.ts`, `docs/human-author/property-tests.json`, and the user's own `docs/human-author/answers-*.txt`. Ignored and readable through `check_path`: `docs/working/*.json` and `*.txt`, which include `round-history.json`, `problem-history.json` and `si-run-id.txt` (state that `scripts/self-improvement.sh:436-442,575` and `archive-working-docs.sh` read).

The gate is the directory, not the kind of file. A commit message or plan that says "X under docs/ is stale" can steer an in-cycle "mechanical fix" to a script, a JSON fixture, or the user's answer transcripts, and `--check-fix` approves it. The comment says these classes are filed. The ignored-file case is the sharpest. An edit there cannot be staged ("Stage named paths only"; git ignores it), so it never appears in the cycle branch's diff or in pr-prep's review. It persists in the working tree and changes the inputs of another loop. This is pass-22 Finding 1's class narrowed to `docs/`, not closed.

**Recommendation:** have `check_fix` require a *tracked* file (drop the ignored branch: `git ls-files --error-unmatch`, or a flag to `check_path`), and a `.md` (or `README.md`) name. Exclude `docs/human-author/`, and the bookkeeping files that already go through `--check-write`. Add a bats case for an ignored `docs/working/*.json` and a tracked `docs/**/*.sh`.

#### 2. `--check-answer` takes any `### Q-NNN` line in either file as the entry, including one inside another entry's code fence, a later duplicate, or a live stub that shadows the archive

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:273-276` and `:291-295` (A); `skills/dev-cycle/SKILL.md:253-261` (B)
**Boundary:** B1
**Move:** 11, 2 (implicit sanitization assumption)
**Confidence:** High (executed)
**Legibility-target:** the user. The real entry shows no answer, yet the brief is closed or kept. A diff reviewer looking at the real entry sees nothing.

**Evidence** (verbatim):
```
$0 == "### " id || index($0, "### " id " ") == 1 { inside = 1; found = 1; next }
inside && /^##/ { inside = 0 }
```
```
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    inrepo "$f" || continue
    r="$(env LC_ALL=C awk -v id="$a" "$ANSWER_AWK" "$f")"
    if [[ -n "$r" ]]; then echo "$r $a"; return; fi
  done
```
The probe (p2) used a real `### Q-12` entry with no answer, an options table only, and status OPEN:
- An earlier entry quoted ```` ``` ```` `### Q-12 · keep-or-drop-x-1` / `Q-12: [2]` ```` ``` ````. The result was `drop Q-12`.
- A later entry did the same for an open `Q-13`. The result was `drop Q-13`. `done` latches, but `inside` re-opens on every matching heading.
- `### Q-40 · stub` / `Q-40: [2]` was appended to questions.md while the archive held `Q-40: [1]`. The result was `drop Q-40`.

Nothing tracks code fences, and nothing detects a duplicate heading. Precondition: write access to a questions file. That same writer could add `Q-12: [2]` under the real heading, so no capability is gained, and the rating stays below the floor. Two things are new. The forgery sits away from the entry it decides, so it is less visible. And it can happen by accident: the archive already uses an "Original entry:" quote pattern (Q-081, Q-083), and a copied heading would trigger it.

**Recommendation:** in ANSWER_AWK, count matching headings across both files (or `exit` at the first entry's end and make a second match return `unrecognized`). Ignore heading lines between ```` ``` ```` fence toggles. Add the three probe shapes to test 33.

#### 3. The bracket rule overrides the first word, so a written "keep, not [2]" reads as drop

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:264-272` (A)
**Boundary:** B1
**Move:** 2
**Confidence:** High (executed)
**Legibility-target:** the user, whose plain-words answer is inverted.

**Evidence** (verbatim):
```
  one = index(span, "[1]") > 0; two = index(span, "[2]") > 0
  if (one != two) return one ? "keep" : "drop"
```
Probe p6: `Q-1: keep, not [2]` → `drop Q-1`. `**Answer:** drop — [1] was the interim` → `keep Q-2`. The comment documents this ("[1] or [2] alone decides"), so the code matches its comment. But the decision applied is the opposite of what the user wrote. No adversary is needed. It is filed here because B1's sink is the user's authority over their briefs. `**Answer:** X` (answer after the bold label) is cut at no point, so any note after the answer counts too.

**Recommendation:** when the first word is `keep`/`drop`/`1`/`2` and a bracket elsewhere disagrees, return `unrecognized`. Cut the span at the first sentence end for the label-outside-bold form.

#### 4. A skip or format mismatch consumes the user's answer, and a blocked `questions.md` is passed over silently

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:291-296` (A); `skills/dev-cycle/SKILL.md:259-261` (B)
**Boundary:** B1
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** the cycle agent and the user, who see a skip reason that misnames the cause.

**Evidence** (verbatim): skill: "`unrecognized` or a skip goes in the record and the final message … In each of these cases add the ID to `Applied:`, so each answer is read once." Script: `inrepo "$f" || continue` … `echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md"`.

Probes, all fail-closed but each consumes the answer:
- A heading with a tab (`### Q-15\t· tab`) → `skip Q-15: no such entry`.
- A CRLF answer (`Q-14: keep\r`) → `unrecognized`. The roadmap readers at `:509`/`:557` strip `\r`, but ANSWER_AWK does not.
- A symlinked questions.md → `inrepo` fails, and the loop falls to the archive without a word. It returned `keep Q-40` from the archive, and for Q-12 it printed `skip …: no such entry`, which misstates the cause.

Digest section 8 does report the symlink, so the cause is visible elsewhere. But the In-flight rule then marks the ID Applied, and the user's real answer is never read.

**Recommendation:** print a distinct skip (`questions.md not read: …`) when `inrepo` fails, and do not add a skipped ID to `Applied:` (only `keep`/`drop`/`unrecognized`). Strip `\r` in ANSWER_AWK as the roadmap readers do.

#### 5. In-flight "ancestor → Done" closes a zero-commit branch or a brief naming the default branch; a merged-then-deleted branch never reaches Done

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:249-252, 262-264` (B)
**Boundary:** B2
**Move:** 5 (invert the model)
**Confidence:** High for the logic (read-static plus p4: `main => ok main a5fe071…`, `feat/real` at main's tip gets the same hash)
**Legibility-target:** the user reading the roadmap's Done and Ideas.

**Evidence** (verbatim): "1. Its branch's hash (from `--check-branch`, as in the Rules) is an ancestor of the default branch → Done." and "3. … and that branch has no commit beyond the default branch (or is `absent`) 14 days after …"

The cases:
- A branch just created for the brief, with no commits yet, is an ancestor, so the next cycle marks it Done and closes the brief. Check 3's own wording expects such branches to be in flight.
- A brief whose branch line says `main` passes `--check-branch` and is Done at once.
- Answer to the brief's question: a merged-then-deleted branch is `absent`. It never reaches Done. It reaches a keep-or-drop entry after 14 days, and a "drop" files shipped work under Ideas.

Only the forcing case is adversarial, and it needs the same write access to a committed brief that could move the item directly. So this is Low.

**Recommendation:** Done requires the hash ≠ the brief's base (commits beyond the default-branch point recorded at brief time), or a merge commit on the default branch's first-parent line naming the branch. Refuse the default branch's own name in `--check-branch` for briefs. Treat `absent` plus a matching merge as Done.

#### 6. Notes (Informational)

- **Symbolic branch refs:** `check_branch` prints the resolved target of a symbolic `refs/heads/<name>`. With an annotated tag as target, that is a tag object, not a commit. p4 printed `feat/syma` → `aee7805…`, which equals `git rev-parse annt`. The default-branch lookup peels `^{commit}`, but `check_branch` does not. Creating that state needs host control (S5), so this is Informational. Peeling for consistency is cheap.
- **Briefs glob cap:** briefs are listed through a glob capped at 50 matches (`check_path` max). Closed briefs stay in the directory, so after about 17 three-brief cycles the newest briefs drop off. Those are the ones that count toward the 3-open limit and must be kept out of the merged-branch deletion list. The overflow prints a skip line, but the skill gives no narrowing recipe for briefs (for example, per-month globs). The deletion still needs the user's approval.
- **Test selectors (pre-existing, not in this delta):** step 4's "run the test it cites" passes a commit-message-derived test name or filter to an exec sink with no check mode. Only the file path goes through `--check-path`.
- **TOCTOU:** `--check-fix`/`--check-write` say `ok`, and the agent edits later in a checkout shared with other sessions. This is the same class as earlier passes, and it is pre-existing.

### Untested bypass candidates

- ANSWER_AWK under BWK awk (macOS) or busybox awk: `$` inside the alternation group `([.,;:!)]|$)`, and `match`/`RLENGTH`. Neither is installed here.
- A NUL byte or an over-long line in questions.md under mawk vs gawk (record handling differs).
- `--check-fix` on a case-insensitive filesystem (`DOCS/…` → the regex refuses it, but `docs/` vs a tracked `Docs/` collision was not set up).
- A hardlinked file under `docs/` pointing at a file outside the repo. `rawfile` checks realpath, not the link count. This needs host control.

Because of these, the `--check-answer` and `--check-fix` guards do not appear in Endorsement Claims as guards. Only specific executed behaviours do.

## Endorsement Claims

- **Claim:** `--check-branch` reports `absent` for a name that exists only as a tag (`feat/t`) or as a tag literally named `refs/heads/feat/u`, and gives the branch's own hash for `feat/real`.
  **Location:** `scripts/dev-cycle.sh:236-245`
  **Evidence:** executed (p4)
  **Verified:** outputs `ok feat/t absent`, `ok feat/u absent`, `ok feat/real a5fe071…`
  **Not verified:** packed-refs-only branches (show-ref reads them, but no probe packed the refs)
  **route: code-fact-check**
- **Claim:** `--check-branch` refuses `HEAD`, `refs/heads/x`, `-x`, `@`, `x.lock`, `a..b`, `main/`, `feat//x`, and accepts `FETCH_HEAD` and `origin/main` only as `refs/heads/…` lookups (`absent`).
  **Location:** `scripts/dev-cycle.sh:238-243`
  **Evidence:** executed (p4)
  **Verified:** the 14 names listed in p4, each with its printed line
  **Not verified:** names using `@{` (refused by NAMECHARS before check-ref-format, by reading, not run)
  **route: code-fact-check**
- **Claim:** with branch `main` deleted and a tag `refs/heads/main` present, the default-branch lookup falls through to the current branch and does not use the tag.
  **Location:** `scripts/dev-cycle.sh:318-332`
  **Evidence:** executed (p3b: Window line names `other` at 6f7e06d)
  **Verified:** the main/master/current-branch path
  **Not verified:** an `origin/HEAD` naming a tag-shadowed branch (no remote was set up)
  **route: code-fact-check**
- **Claim:** `MAIN` appears only in printed text. Every git invocation in the digest after the lookup takes `$MAIN_SHA`.
  **Location:** `scripts/dev-cycle.sh:379,382,540` (git uses); `:372`, `:384`, `:546-547` (printed text)
  **Evidence:** read-static
  **Verified:** grep of all `MAIN`/`MAIN_SHA` uses in the file
  **Not verified:** functions defined before line 340 that might read `MAIN` (none reference it, by the same grep's scope)
  **route: code-fact-check**
- **Claim:** a question ID reaches awk only after `^Q-[0123456789]+$`, and awk matches it with `index`/`==`, not as a regex. `Q-10` does not match `### Q-100 …`.
  **Location:** `scripts/dev-cycle.sh:273, 290`
  **Evidence:** executed (p2: `open Q-10`, `keep Q-100`; `Q-1 2` → shape skip)
  **Verified:** prefix IDs and an ID with a space
  **Not verified:** a leading-zero alias (`Q-012` vs `### Q-12`). It printed `skip`, which consumes the answer (Finding 4).
  **route: code-fact-check**
- **Claim:** across the 102 real entry headings in wt-devcycle's questions.md and archive, there is no duplicate heading. Each of the 45 keep/drop readings comes from a `[1]`/`[2]` inside the bold or after the answer label, and no line other than a `**Answer…**`/`Q-NNN:` line was read as an answer.
  **Location:** `docs/working/questions{,-archive}.md` @ f2843cd
  **Evidence:** executed (p1, plus a per-ID extraction of the line read)
  **Verified:** 19 drop, 26 keep, 13 open, 44 unrecognized, with each keep/drop line inspected
  **Not verified:** whether any of those is a keep-or-drop question (none are, so the semantic mapping is untested on real keep-or-drop answers)
- **Claim:** `--check-fix` refuses globs, `readme.md`, `sub/README.md`, `docs` (the directory), `.github/x`, and `docs/../README.md`.
  **Location:** `scripts/dev-cycle.sh:248-253`
  **Evidence:** executed (p3b)
  **Verified:** the six refusals with their reasons
  **Not verified:** a tracked symlink under `docs/` (covered by `check_path`'s `inrepo`, by reading only)

## Primitive sweep

Primitive: git invocation with a value derived from repo text or refs
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:239` `git check-ref-format "refs/heads/$a"` / `--branch "$a"` | S3 | NAMECHARS, no leading `-` | cleared, executed |
| `scripts/dev-cycle.sh:242` `git show-ref --verify --hash "refs/heads/$a"` | S3 | above + HEAD/refs/* refusal | cleared (tag shadowing executed); symbolic-ref note in 6 |
| `scripts/dev-cycle.sh:322` `git show-ref --verify --hash "refs/heads/$c"` | S6, S5 | leading-`-` skip | cleared, executed |
| `scripts/dev-cycle.sh:323` `git rev-parse --verify --quiet "$sha^{commit}"` | S5 (hash) | hex from show-ref | cleared |
| `scripts/dev-cycle.sh:191,195` `git ls-files -- "$1"` (via check_fix → check_path) | S4 | pathform, `:(literal)` | cleared |
| SKILL.md:249 ancestry test with `--check-branch` hash | S3 | hash only | Finding 5 (logic, not injection) |
| SKILL.md:146-149 merged-branch listing / skip | S3 (names compared, not passed) | briefs via glob | note in 6 (50 cap) |

Primitive: file read
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:293` awk on questions files | S1 | `inrepo` | Findings 2, 4 |
| SKILL.md:74 brief listing via `--check-path` glob | S1/B5 | `check_path` per match | cleared (pass-22 F3 closed); cap note in 6 |
| SKILL.md:75-76 roadmap brief paths | S4 | `--check-brief` + `--check-path` | cleared |

Primitive: file edit
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| SKILL.md:71-74 in-cycle fix | S4 | `--check-fix` | Finding 1 |
| SKILL.md:68-70 bookkeeping writes (brief `Applied:`/`Kept:`/`Status:`) | S4 | `--check-write` | cleared (unchanged this pass) |

Primitive: exec of repo-text-derived argument
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| SKILL.md:186 step 4 "run the test it cites" | S1-like (commit text) | path via `--check-path` only | not analyzed beyond reading, pre-existing (note in 6) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `--check-fix` admits scripts, user records and gitignored state under docs/ | Medium | B3 | `scripts/dev-cycle.sh:246-253` | High (mechanism) / Medium (use) |
| 2 | `--check-answer` takes spoofed/duplicate `### Q-NNN` headings (fences, later copies, live stub over archive) | Low | B1 | `scripts/dev-cycle.sh:273-276, 291-295` | High |
| 3 | Bracket overrides first word: "keep, not [2]" → drop | Low | B1 | `scripts/dev-cycle.sh:264-272` | High |
| 4 | Skip/CRLF/tab/symlink cases consume the answer; blocked questions.md passed over silently | Low | B1 | `scripts/dev-cycle.sh:291-296`, SKILL.md:259-261 | High |
| 5 | Ancestor→Done closes zero-commit or `main` briefs; merged-then-deleted never Done | Low | B2 | SKILL.md:249-252, 262-264 | High |
| 6 | Notes: symbolic-ref hash, briefs 50-cap, test selectors, TOCTOU | Informational | B2/B5/B3 | various | Medium |

## Overall Assessment

The branch-by-hash change and the default-branch lookup hold under every probe. A tag of either shape no longer stands in for a branch, and git receives only hashes. These fixes close pass 22's Medium on `refs/heads/<name>` tag shadowing. The brief listing through `--check-path` closes pass 22's symlinked-brief Medium. The remaining Medium is the scope of `--check-fix`. It is a directory rule, so it approves tracked scripts and the user's answer transcripts under `docs/`, plus gitignored state files whose edits never reach a reviewed diff. Fix it in place: require tracked `.md` files and exclude `docs/human-author/`. `--check-answer` is fail-closed for malformed input, but it trusts any matching heading anywhere in either file. Rejecting duplicates and fenced headings would make its reading match the entry the user actually answered. No findings within the code paths read rise above Medium. Endorsement claims are executed where marked. The rest are pending execution verification, and the `--check-answer`/`--check-fix` guards are not endorsed as guards because of the untested bypass candidates above.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."
This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass23.md`, with first line `Commit: ba39470 (A) / 36ca12c (B)`. It follows the security-reviewer structure: trust boundary map with source table, anchored findings carrying Severity/Location/Evidence/Confidence/Legibility-target, untested bypass candidates, endorsement claims with `route: code-fact-check`, primitive sweep, summary and overall assessment. Against the user goal (merge once a clean pass is reached), this pass is **not clean**: one Medium (Finding 1) and four Lows remain for the next k=1 delta pass.
