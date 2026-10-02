Commit: 723c242 (A) / 1f36885 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at 723c242; HEAD d0f1c6a adds review docs only, `git diff --stat 723c242 HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at 1f36885; HEAD e136dbe merges the digest branch, and `git show 1f36885:skills/dev-cycle/SKILL.md` is byte-identical to `git show HEAD:...`).
**Scope:** Partial: the full-review fix round only. A: `git diff 09f6fe7..723c242 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the message of commit 723c242. B: `git diff 074164b..1f36885 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/working/seed-build-loop-handoff.md` plus the message of commit 1f36885. Everything else on both branches is context only.
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 27
**Summary:** 21 verified, 3 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Execution logs (scratch, not committed) are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc17/` (below, `fc17/`). Every throwaway repo was built under its own `mktemp -d` directory, removed on exit; every process ran under `timeout`. Nothing was written to either worktree except this report.

**Working-tree note.** During this run, at 07:46:23Z, A's working tree gained an uncommitted edit to `scripts/dev-cycle.sh` (lines 207-225: `--diff-merges=combined` and a `${last_date[$f]+set}` fallback), and at 07:46:45Z B's gained edits to `skills/dev-cycle/SKILL.md` and `docs/dev-cycle.md`. This run did not make them. To keep every verdict on the committed code, all A executions were re-run against `git archive 723c242 scripts test` extracted to `fc17/a723/` (its `scripts/dev-cycle.sh` has sha256 `2f54c34b…`, the same as `git show 723c242:scripts/dev-cycle.sh`). Every B line number refers to `fc17/SKILL-1f36885.md` and `fc17/dev-cycle-1f36885.md` (`git show 1f36885:<path>`). This report does not verdict the uncommitted edits.

- `bats.out`: `timeout 600 bats test/scripts/dev-cycle.bats`, cwd `fc17/a723`, exit 0, 2026-10-02T07:47:47Z to 07:47:55Z, 23/23 ok.
- `shellcheck.log`: `timeout 60 shellcheck scripts/dev-cycle.sh test/scripts/dev-cycle.bats`, cwd `fc17/a723`, exit 0, 0 bytes, 2026-10-02T07:47:55Z.
- `probe-dates.out` (script `fc17/probe-dates.sh`): `TMPDIR=fc17 timeout 300 bash probe-dates.sh`, cwd `fc17`, exit 0, 2026-10-02T07:47:46Z. A throwaway repo with 8 records (plain, renamed, tab name, `"` name, `\` name, non-ASCII name, merge-only, merge-edited, uncommitted). It prints the old rule's per-file `git log -1` date for each record next to section 2's heading from the 723c242 digest.
- `probe-opts.out` (script `fc17/probe-opts.sh`): same form, exit 0, 2026-10-02T07:47:47Z. Covers every option form, `--help`, section 7 with subpaths and quoted names, an empty questions doc, and a symlinked `docs/dev-cycle.md` and `docs/working/briefs`.
- `probe-qs.out` (script `fc17/probe-qs.sh`): same form, exit 1 (the last command is the expected digest failure), 2026-10-02T07:47:47Z. Runs B's `scripts/questions.sh` `init` with a dangling symlinked archive, `init`, `check`, `archive`, `check`, then the 723c242 digest with an impossible-date cycle record name.
- `realrepo-perfile.tsv`, `realrepo-map.tsv`, `realrepo-diff.txt`: cwd `/workspace/.claude/wt-digest`, 2026-10-02T07:44:17Z, git reads only. For each of the 32 `docs/decisions/[0-9]{3}-*.md` at 723c242 they hold `git log -1 --format=%ad --date=short 723c242 -- f`, the 723c242 map pipeline (`git -c core.quotePath=false log 723c242 --format='@%ad' --date=short --name-only -- docs/decisions | awk …`), and the join of the two. `realrepo-diff.txt` is empty: 0 mismatches.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) present and consulted. No claim matches a logged pattern. The two Incorrect verdicts are behavioral mismatches, not fabricated symbols, so nothing qualifies for the log (and the brief allows no write besides this report).

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest or the record).

---

## Claim 1: "Relative paths inside the repo only (no leading `/` or `~`, no `..`), never through a symlink."

**Location:** `docs/dev-cycle.md:26-28`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers agreement with the skill's rule (commit 1f36885: "docs/dev-cycle.md says the same") and compliance of the one current row; does not establish that the rule is complete (Claim 12).

The skill says: "A path taken from repo text (a settings row, a brief link) must be relative, must not start with `/` or `~`, and must have no `..` component. Then, before each read or write, check that no part of the path below the repo root is a symlink" (`skills/dev-cycle/SKILL.md:63-65`). The settings file gives the same three conditions and the symlink rule. Its one row, `| Feature ideas | docs/working/feature-ideas*.md | ... |` (`docs/dev-cycle.md:32`), passes them.

**Evidence:** `docs/dev-cycle.md:26-32`, `skills/dev-cycle/SKILL.md:61-70`

---

## Claim 2: "Never read or write through a symlink. The digest enforces this for its own reads (`inrepo`, `dirok`); it writes nothing, so the handoff unit needs its own write check."

**Location:** `docs/working/seed-build-loop-handoff.md:40-41`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the digest's read guards and that it writes nothing to the repo; does not establish that every read uses those two functions (globbed records use `rawfile` directly, which the digest documents).

The guards: `inrepo() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` and `dirok() { [[ -z "$(blocker "$1" dir)" && -d "$1" ]]; }` (`scripts/dev-cycle.sh:119,122`). The header says "Read-only: writes nothing to the repo (one temp file, removed on exit)" (`:20`). The only write is `qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT` (`:274`), and `mktemp` with no template writes under `$TMPDIR`, not the repo. Glob items use `rawfile "$f"` (`:154`, `:218`), and a comment says so: "(Glob items use rawfile directly: their directory has already passed dirok.)" (`:117-118`). The seed's "(`inrepo`, `dirok`)" therefore names examples, not an exhaustive list.

**Evidence:** `scripts/dev-cycle.sh:20`, `scripts/dev-cycle.sh:94-122`, `scripts/dev-cycle.sh:274`

---

## Claim 3: "Since the split, the cycle writes its build briefs to `docs/working/briefs/` (the quoted text below still says `handoffs/`), and keep-or-drop questions are keyed on IDs recorded in each brief (`Asked:`, `Applied:`)"

**Location:** `docs/working/seed-build-loop-handoff.md:43-45`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the brief path, the quoted text's old path and the ID keying; does not establish anything about the handoff design itself (context).

The skill writes "`docs/working/briefs/YYYY-MM-DD-<slug>.md`" (`skills/dev-cycle/SKILL.md:259`). The quoted text in the seed still says "`docs/working/handoffs/YYYY-MM-DD-<slug>.md`" (`docs/working/seed-build-loop-handoff.md:84`) and "`docs/working/handoffs/`" (`:91`). Keying: "the IDs on its `Asked:` line (step 3 below writes them; no other question counts)" (`SKILL.md:235-236`) and "For each answered ID not yet on its `Applied:` line" (`:238`).

**Evidence:** `docs/working/seed-build-loop-handoff.md:43-45`, `docs/working/seed-build-loop-handoff.md:84-91`, `skills/dev-cycle/SKILL.md:234-247`, `skills/dev-cycle/SKILL.md:259`

---

## Claim 4: "Default: the date in the newest cycle-YYYY-MM-DD.md in docs/working/cycles that is a plain file and not future-dated (only its name is read), else 14 days ago. The digest says which." (and commit 723c242: "--help describes the default window exactly")

**Location:** `scripts/dev-cycle.sh:12-14`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the selection loop (`:150-164`), the fallback (`:166-180`) and validation (`:181`), read whole; does not establish anything about the `--since` override path beyond the parse (Claim 5).

The selection matches the text: `[[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated` (`:160`), only after `rawfile "$f"` passes (`:154`), and otherwise `SINCE="$(date -d "$TODAY - 14 days" +%F)"` (`:174`). The "exactly" is one case short. The glob takes the date's shape, not its validity: `cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`:152`). So the newest name can be an impossible date. That date then fails `if ! [[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || ! date -d "$SINCE" >/dev/null 2>&1; then echo "--since must be a real YYYY-MM-DD date" >&2; exit 1; fi` (`:181`). Executed: with only `docs/working/cycles/cycle-2026-02-30.md` present and no option, the digest exits 1 with `--since must be a real YYYY-MM-DD date` (`fc17/probe-qs.out`). It does not fall back to 14 days ago, and the message names an option the user did not pass. Precise version: "the newest valid date in …; a name with an impossible date stops the digest". The behavior predates this round (`:181` is unchanged in the diff), so this is wording for this round, with a pre-existing narrow behavioral residue. Precondition: a hand-made record name with an impossible date.

**Evidence:** `scripts/dev-cycle.sh:12-14`, `scripts/dev-cycle.sh:150-181`, `fc17/probe-qs.out`

---

## Claim 5: Option parser: `--since X`, `--since=X`, `--since=`, `--since` last, the same for `--sample`, and `--help` (commit 723c242: "`--since=` with an empty value and a missing value are rejected with a plain "needs a value" message (no bash line prefix)")

**Location:** `scripts/dev-cycle.sh:72-85`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers every listed form plus `--since ''`, `--sample=-1`, `--since --sample` and the `--help` line range; does not establish handling of repeated options (the last one wins, by reading the loop).

The parser:

```bash
# scripts/dev-cycle.sh:74-81 (excerpt ends :81; the case continues to :83 and the loop to :84 — read; :85 validates --sample)
need() { [[ -n "$2" ]] || { echo "$1 needs a value" >&2; exit 1; }; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) need --since "${2:-}"; SINCE="$2"; shift 2 ;;
    --since=*) SINCE="${1#--since=}"; need --since "$SINCE"; shift ;;
    --sample) need --sample "${2:-}"; SAMPLE="$2"; shift 2 ;;
    --sample=*) SAMPLE="${1#--sample=}"; need --sample "$SAMPLE"; shift ;;
    -h|--help) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```

Executed (`fc17/probe-opts.out`): `--since 2026-01-01` and `--since=2026-01-01` give exit 0 with "Window: since 2026-01-01 (from --since)". `--since=`, `--since` (last) and `--since ''` give exit 1 with stderr `--since needs a value`. `--sample 3` and `--sample=3` give exit 0. `--sample=` and `--sample` give exit 1 with `--sample needs a value`. `--sample=-1` gives exit 1 with `--sample must be a non-negative integer`. `--since --sample` gives exit 1 with `--since must be a real YYYY-MM-DD date`, because the flag is taken as the value and then fails date validation. No stderr carries a `line N:` prefix. `--help` prints lines 2-22. Line 22 is the header's last comment line (`# perl; … Printed repo text is data.`) and line 23 is blank, so nothing is cut or leaked.

**Evidence:** `scripts/dev-cycle.sh:72-85`, `fc17/probe-opts.out`

---

## Claim 6: "Every trigger, in full: each decision record's `## Revisit triggers` section and each decision-log row that mentions revisiting (a trigger written elsewhere in a record is not found; an output line over 4096 bytes is cut: read the record itself then)."

**Location:** `scripts/dev-cycle.sh:201`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers which records and rows are scanned and what part is printed; does not establish discovery of records outside the `NNN-*.md` naming (a `0042-x.md` or a record in a subdirectory is not scanned and is not named), and for log rows prints only the clause from "Revisit" to the cell's end, not the whole row.

Records: `decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md)` (`:206`). Only those with `grep -q '^## Revisit triggers' "$f"` print (`:219`), and `trig()` prints that section's non-blank lines up to the next `## ` (`:203`). Rows: `grep -E '^\| [0-9]+ \|' docs/decisions/log.md | grep -i 'revisit'` (`:238`), printing `grep -oE 'Revisit[^|]*'`, else the case-insensitive form (`:235-236`). This is the repo's documented record naming (`docs/decisions/NNN-title.md`). On this repo's 9 matching log rows, every printed clause starts with the trigger sentence's "Revisit" (checked by a read-only loop over `docs/decisions/log.md`; paraphrased — no quote available because the output is nine row-number/prefix pairs not saved to a file).

**Evidence:** `scripts/dev-cycle.sh:201-241`

---

## Claim 7: "Each record's last commit date, from one path-limited walk (newest first, so the first date seen per path wins) instead of one `git log` per record" (commit 723c242: "Section 2 takes every record's last commit date from one path-limited walk instead of one `git log` per record")

**Location:** `scripts/dev-cycle.sh:207-209`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers records whose newest change is a merge commit's own diff (merge-only and merge-edited records), in a probe repo; does not establish equality for history-simplification differences between a directory and a single-file pathspec (not probed), and does not cover the quoted-name case (Claim 8).

The walk is `git -c core.quotePath=false log --format='@%ad' --date=short --name-only -- docs/decisions` (`:214`). Without a `--diff-merges` option, `git log` prints no file list for a merge commit. A change that exists only in a merge's own result (a conflict resolution, or a file added while merging) is therefore never in the map. The old per-file `git log -1 -- "$f"` did count such a merge. Executed (`fc17/probe-dates.out`):

```
docs/decisions/001-plain.md => 2026-01-10          (old: per-file)
### docs/decisions/001-plain.md (last committed on this branch: 2026-01-08)
docs/decisions/008-mergeonly.md => 2026-01-07
### docs/decisions/008-mergeonly.md (last committed on this branch: never, uncommitted)
```

`001-plain.md` was last changed in the merge on 2026-01-10. The map gives the side-branch commit (2026-01-08). `008-mergeonly.md` was added in a merge, and the digest calls it "never, uncommitted". So the comment's "Each record's last commit date" does not hold for these records. Renamed, non-ASCII, tab-named and uncommitted records matched the old rule in the same probe. On this repo the 32 records match (Claim 21), so the defect needs the precondition: a decision record whose newest change was made in a merge commit, which happens when two branches edit one record and the conflict is resolved in the merge. **Behavioral.** The heading's date is the context the agent weighs for "fired / not fired". A committed record shown as "never, uncommitted", or an older date, misleads it. Severity: low to medium (context data, not a trigger's text).

**Evidence:** `scripts/dev-cycle.sh:207-227`, `fc17/probe-dates.sh`, `fc17/probe-dates.out`

---

## Claim 8: "A name git still quotes (a control character) misses the map and falls back to its own lookup."

**Location:** `scripts/dev-cycle.sh:209-210`, `scripts/dev-cycle.sh:223`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers names with a tab, a double quote or a backslash; does not establish other characters git quotes beyond those three (git also quotes other C0 bytes, which `[[:cntrl:]]` does catch).

The fallback condition is `[[ -n "$d" || "$f" != *[[:cntrl:]]* ]] || d="$(git log -1 --format=%ad --date=short -- "$f")"` (`:223`). git quotes a path that contains `"` or `\` even with `core.quotePath=false`, and neither character is a control character. Such a name therefore misses the map and skips the fallback. Executed (`fc17/probe-dates.out`): the old rule gives `docs/decisions/005-q"x.md => 2026-01-04` and `docs/decisions/006-b\x.md => 2026-01-04`, while the digest prints `(last committed on this branch: never, uncommitted)` for both. The tab-named record falls back correctly (`2026-01-04` in both). **Behavioral.** Precondition: a committed record whose name contains `"` or `\`. That is rare, but the comment presents control characters as the only quoted class.

**Evidence:** `scripts/dev-cycle.sh:209-225`, `fc17/probe-dates.out`

---

## Claim 9: "Open by route: none" when nothing is open (commit 723c242: "an empty "Open by route" says none")

**Location:** `scripts/dev-cycle.sh:285-286`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers an initialized, empty questions doc; does not establish the populated-route formatting (unchanged; context).

`routes="$(… | awk … )"` then `echo "Open by route: ${routes:-none}"` (`:285-286`). Executed after `questions.sh init` in a probe repo: section 3 prints "None open." then "Open by route: none" (`fc17/probe-opts.out`).

**Evidence:** `scripts/dev-cycle.sh:273-292`, `fc17/probe-opts.out`

---

## Claim 10: Section 7 counts "any file under skills/ or workflows/" (commit 723c242), and "the patterns below accept the quote"

**Location:** `scripts/dev-cycle.sh:335-342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers subpaths, top-level files and quoted names under both roots; does not establish anything about the records pattern (`:343`, unchanged) or about renames out of the pathspec.

`skills_changed="$(printf '%s\n' "$changed" | grep -E '^"?(skills|workflows)/' || true)"` (`:342`). `changed` is already limited to `-- skills workflows docs/decisions` (`:340`). Executed (`fc17/probe-opts.out`): after one commit adding `skills/s/references/ref.md`, `workflows/sub/deep.md`, `skills/top.txt`, `skills/s/q"x.md` and a tab-named skills file, the count is 5, and the list includes `"skills/s/q\"x.md"` and `"skills/s/tab\tx.md"`.

**Evidence:** `scripts/dev-cycle.sh:334-352`, `fc17/probe-opts.out`

---

## Claim 11: "The dev-cycle skill also reads these; they are checked here so that a non-plain one is listed below like every other input." (`docs/dev-cycle.md`, `docs/working/briefs`)

**Location:** `scripts/dev-cycle.sh:385-388`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers symlinked instances of both; does not establish anything about briefs below a plain `docs/working/briefs/` (the digest does not walk into it), and these two checks add no inline note outside section 8.

`skipped docs/dev-cycle.md || true` and `skipdir docs/working/briefs || true` (`:387-388`) run before section 8 prints `SKIPPED` (`:390-396`). Executed: with `docs/dev-cycle.md -> /etc/hostname` and `docs/working/briefs -> /etc`, section 8 lists `- docs/dev-cycle.md` and `- docs/working/briefs/` (`fc17/probe-opts.out`). The checks run after section 2's `n_before_triggers` slice (`:244-248`), so they do not add false "Not read" lines to section 2.

**Evidence:** `scripts/dev-cycle.sh:123-124`, `scripts/dev-cycle.sh:385-396`, `fc17/probe-opts.out`

---

## Claim 12: "The cycle reads and writes repo files (idea sources and their glob matches, the idea log, briefs, the record, the roadmap, questions) only by plain paths inside the checkout. A path taken from repo text (a settings row, a brief link) must be relative, must not start with `/` or `~`, and must have no `..` component."

**Location:** `skills/dev-cycle/SKILL.md:61-67`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers every write the skill makes and the two named repo-text sources; does not establish safety for repo-text paths read outside the enumerated list (step 4's cited plans and tests, step 2's evidence) or for what a brief link may point at, and it is an instruction an agent applies, so it is not executable here.

As an agent would apply it, the rule is complete for the enumerated files. The writes use fixed or constrained names: the record `docs/working/cycles/cycle-YYYY-MM-DD.md` (`:269`), `docs/roadmap.md` (`:213`), `docs/working/idea-log.md` (`:73`), questions through `questions.sh` (which refuses symlinked targets on its own), and briefs at `docs/working/briefs/YYYY-MM-DD-<slug>.md`, "where the slug is lowercase letters, digits and hyphens only" (`:259-260`). No write can take a `/` or `..` from repo text. Idea-source rows and brief links get the lexical check and then the symlink walk. Three residues sit outside the list or the check:

- **(a)** A brief link is checked to be in-repo, but nothing requires it to be under `docs/working/briefs/`. In flight item 1 then writes into it: "Either way the brief gets `Status: closed`" (`:233`). So a roadmap link to any plain in-repo file is a write target. **Behavioral, low.** Precondition: an edited roadmap link.
- **(b)** Step 4 picks claims "from its commit message, decision-log row, or plan" and runs "the test it cites if that test exists" (`:168-170`). These paths come from repo text, but they are not in the rule's list and carry no lexical or symlink check. The Rules bullet says "Run only commands this skill names and tests that exist in the repo's test tree" (`:25`), which limits commands, not file reads. **Behavioral, low.** Precondition: a commit or plan naming an out-of-repo or symlinked path. Step 4's subagents are read-only.
- **(c)** A glob component such as `.*` could expand to `..` in bash older than 5.2, where `globskipdots` does not exist. The rule's `..` check is applied to the text before expansion. This sandbox runs bash 5.2.15, where `globskipdots` is on by default (paraphrased — no quote available because this is shell-version behavior, not repo code).

The claim's mechanism holds for what it lists, so the verdict is Mostly accurate, not Incorrect. Tighten it by naming brief links as `docs/working/briefs/` paths, and by extending the lexical rule to any file path taken from repo text, step 4's included.

**Evidence:** `skills/dev-cycle/SKILL.md:22-26`, `skills/dev-cycle/SKILL.md:61-70`, `skills/dev-cycle/SKILL.md:166-174`, `skills/dev-cycle/SKILL.md:229-247`, `skills/dev-cycle/SKILL.md:257-265`, `skills/dev-cycle/SKILL.md:269`, `scripts/questions.sh:95-107`

---

## Claim 13: "The digest applies the same rule to everything it reads (and also skips anything that is not a regular file or directory) and lists what it skipped in its section 8."

**Location:** `skills/dev-cycle/SKILL.md:68-70`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the digest's file and directory reads and the section 8 listing; does not establish anything about git-object reads (history, not files), which the rule does not concern.

The digest's test is stricter than the lexical rule. `rawfile` requires `[[ "$r" == "$ROOT_REAL/$1" ]]` for `r="$(realpath -e -- "$1")"` (`scripts/dev-cycle.sh:94`), which rejects `..`, absolute and symlinked paths alike, and `plaindir` does the same for directories (`:97`). The digest takes no path from repo text: its inputs are fixed names and fixed-shape globs (paraphrased — no quote available because the claim covers absence: every `inrepo`/`dirok`/`rawfile` argument in `scripts/dev-cycle.sh` is a literal or a glob match). Section 8 prints `SKIPPED` (`:390-396`), and the two inputs newly checked this round are listed (Claim 11, executed).

**Evidence:** `scripts/dev-cycle.sh:94-125`, `scripts/dev-cycle.sh:385-396`, `fc17/probe-opts.out`

---

## Claim 14: "before the cycle branch is created (the Rules' "Its own branch")"

**Location:** `skills/dev-cycle/SKILL.md:94-95`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the cross-reference resolves and is consistent with step 1; does not establish when exactly the branch is created (the Rules say "Before the first change", which in step 1 is `questions.sh init` or the first cleanup fix).

The Rules contain "**Its own branch.** Before the first change, check `git branch --show-current` and create `chore/dev-cycle-<date>` from the default branch" (`:27-28`). Step 1 then says "run `~/.claude/scripts/questions.sh init` now, on the cycle branch" (`:125-126`), which is consistent.

**Evidence:** `skills/dev-cycle/SKILL.md:27-31`, `skills/dev-cycle/SKILL.md:94-96`, `skills/dev-cycle/SKILL.md:125-130`

---

## Claim 15: "If the digest says the repo has no `docs/working/questions.md`, step 1 creates it." / "run `questions.sh init` now, on the cycle branch; if it fails (no questions.sh, a symlinked archive) or the digest listed the archive in section 8, note it in the record. Then `questions.sh archive` (it also reindexes)"

**Location:** `skills/dev-cycle/SKILL.md:101-102`, `skills/dev-cycle/SKILL.md:125-130`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the digest's absence message, init's refusal on a symlinked archive, and archive's reindex; does not establish what the cycle does when questions.md exists but the archive is missing (the digest reports `questions.sh open failed` and step 1 runs no init, so `archive` fails too, which step 3's "fix or report that first" covers), nor what to do after a failed init (the "Then" archive also fails, harmlessly).

The digest prints "No docs/working/questions.md in this repo." (`scripts/dev-cycle.sh:268`). Init calls `assert_write_targets` first, and that check contains `[[ -L "$file" ]] && die "refusing to write: $file is a symlink"` (`scripts/questions.sh:98`, called from `cmd_init` at `:423`). Archive ends with `cmd_index` (`scripts/questions.sh:393`). Executed (`fc17/probe-qs.out`): `init` with a dangling symlinked archive exits 1 with "refusing to write: …questions-archive.md is a symlink" and creates no live file. A clean `init` creates both files. Then, with an ANSWERED entry and a stale index, `check` exits 1 ("index is stale"). `archive` reports "→ archived Q-001 / ✓ indexes regenerated" and exits 0. A following `check` passes ("structure valid, indexes current") with no separate `index` run. The digest lists a skipped archive in section 8 via `qa_at=""; skipped "$QA" && qa_at="$SKIP_AT"` (`scripts/dev-cycle.sh:263`).

**Evidence:** `scripts/dev-cycle.sh:263-268`, `scripts/questions.sh:95-110`, `scripts/questions.sh:374-395`, `scripts/questions.sh:419-444`, `fc17/probe-qs.out`

---

## Claim 16: Briefs live in `docs/working/briefs/`, the slug is "lowercase letters, digits and hyphens only", and the rename is applied everywhere

**Location:** `skills/dev-cycle/SKILL.md:133`, `skills/dev-cycle/SKILL.md:259-261`
**Type:** Staleness / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers every live mention in both branches' code and the skill; does not establish anything about the quoted historical text in the seed, which deliberately keeps `handoffs/` and says so (Claim 3).

`git grep -n 'handoffs\|working/briefs\|briefs/' 1f36885` (excluding `docs/reviews`, `archive`) finds `docs/working/briefs/` at `SKILL.md:133` and `:259`, the digest's `skipdir docs/working/briefs` (`scripts/dev-cycle.sh:388` at 723c242), and `handoffs/` only in the seed's quoted 8b3a8ad text (`seed-build-loop-handoff.md:84,91`) and its note (`:44`). The other `handoffs` hits are unrelated prose about workflow handoffs (paraphrased — no quote available because the grep hits are three unrelated prose sentences, in `docs/superpowers/plans/…`, `docs/working/feature-ideas.md` and `global-instructions/CLAUDE.md`).

**Evidence:** `skills/dev-cycle/SKILL.md:133`, `skills/dev-cycle/SKILL.md:259-261`, `docs/working/seed-build-loop-handoff.md:43-45`, `docs/working/seed-build-loop-handoff.md:84-91`, `scripts/dev-cycle.sh:388`

---

## Claim 17: ""[1]" or "keep" sets `Kept: <today>` (YYYY-MM-DD); "[2]" or "drop" closes the brief as in 1; any other answer changes nothing. … with options **[1] keep** and **[2] drop**, and add its ID to `Asked:` (IDs separated by ", ")"

**Location:** `skills/dev-cycle/SKILL.md:236-247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers agreement between the options the cycle files and the answers it accepts, and the ID and date formats; does not establish handling of an unbracketed "2" or "Keep."-style answers, which fall under "any other answer changes nothing" and are still added to `Applied:` (see Claim 25).

Step 3 files options "**[1] keep** and **[2] drop**" (`:245-246`), and step 2 accepts exactly "[1]" or "keep", and "[2]" or "drop" (`:238-239`). This matches the global grammar's answer form `Q-NNN: [2]`. The separator is stated for both lines (`:238`, `:246`), and `Kept:` is given as YYYY-MM-DD (`:239`). Answers come from `questions.md` or `questions-archive.md` "once the cycle's step 1 has archived it" (`:236-237`), consistent with step 1's archive (`:129`).

**Evidence:** `skills/dev-cycle/SKILL.md:125-130`, `skills/dev-cycle/SKILL.md:229-247`

---

## Claim 18: `@test "prints all eight sections in a repo with no docs"`

**Location:** `test/scripts/dev-cycle.bats:37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the test name and its heading loop; does not establish anything beyond the asserted strings.

The loop asserts eight headings, `"## 1. Activity"` through `"## 8. Skipped inputs"` (`:40-42`). Executed: `ok` in `fc17/bats.out` (23/23).

**Evidence:** `test/scripts/dev-cycle.bats:37-48`, `fc17/bats.out`

---

## Claim 19: "An empty value is an error, not "no flag", and the message is plain."

**Location:** `test/scripts/dev-cycle.bats:367-373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `--since=` (status, message, no `line ` prefix) and `--sample` (status only); does not establish that the test asserts the `--sample` message or the `--sample=` form, which the probe covers instead (Claim 5).

`run --separate-stderr bash "$DC" --since=` then `[[ "$stderr" == *"--since needs a value"* && "$stderr" != *"line "* ]]`, and `run --separate-stderr bash "$DC" --sample` then `[ "$status" -eq 1 ]` (`:368-373`). The test passes (`fc17/bats.out`).

**Evidence:** `test/scripts/dev-cycle.bats:360-374`, `fc17/bats.out`

---

## Claim 20: Commit 723c242: "the reverted skill file is asserted"

**Location:** `test/scripts/dev-cycle.bats:406`, `test/scripts/dev-cycle.bats:426`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the add-then-remove fixture and the count and line assertions; does not establish any other skills/ subpath shape (Claim 10 covers more).

The fixture is `echo t > skills/demo/tmp.md && git add -A && git commit -q -m tmp && git rm -q skills/demo/tmp.md && git commit -q -m untmp` (`:406`). The assertions include `"in the window: 4"` and `"    - skills/demo/tmp.md"` (`:426`). The pre-change pattern `skills/.*/SKILL\.md` would not have listed it. The test passes (`fc17/bats.out`).

**Evidence:** `test/scripts/dev-cycle.bats:401-430`, `fc17/bats.out`

---

## Claim 21: Commit 723c242: "Output identical on this repo."

**Location:** commit 723c242 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers all 32 `docs/decisions/[0-9]{3}-*.md` records at 723c242; does not establish equality on other repos (Claims 7 and 8).

Per-file dates and the map pipeline were computed side by side and joined: 32 records, 0 mismatches (`fc17/realrepo-diff.txt` is empty; inputs `fc17/realrepo-perfile.tsv`, `fc17/realrepo-map.tsv`; command in the header).

**Evidence:** `scripts/dev-cycle.sh:211-216`, `fc17/realrepo-perfile.tsv`, `fc17/realrepo-map.tsv`, `fc17/realrepo-diff.txt`

---

## Claim 22: Commit 723c242: "on a 200k-commit repo section 2 alone passed the 120 s Bash default above ~141 records"

**Location:** commit 723c242 (message body)
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the claim's provenance only; does not establish the measurement.

The figure traces to the full review's performance finding (rubric row C1: "above ~141 records at 200k commits it passed the 120 s Bash default", `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:509`). It was not re-measured here. That would take a 200k-commit repo with more than 141 records, which is too large to build for a loop pass, and the claim only motivates the change, not its behavior.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:509`

---

## Claim 23: Commit 723c242: "23/23; shellcheck clean."

**Location:** commit 723c242 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the committed script and test file; does not establish anything about the uncommitted working-tree edit (see header).

`bats` gives 23 `ok` and no `not ok` (`fc17/bats.out`, exit 0). `shellcheck scripts/dev-cycle.sh test/scripts/dev-cycle.bats` exits 0 with empty output (`fc17/shellcheck.log`, 0 bytes). Both ran against `fc17/a723/`.

**Evidence:** `fc17/bats.out`, `fc17/shellcheck.log`

---

## Claim 24: Commit 1f36885: "Path rule restored (regression from 1ae9b21)"

**Location:** commit 1f36885 (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers what 1ae9b21 removed and that 1f36885 states it again; does not establish that the restored form is complete (Claim 12).

Before 1ae9b21 the rule said paths "must resolve, symlinks followed, to a path inside the checkout: the digest's `inrepo` rule" (`git show 1ae9b21 -- skills/dev-cycle/SKILL.md`, removed lines). 1ae9b21 replaced it with a symlink-only check, which a `../x` or `/abs` path with no symlink passes. 1f36885 adds "must be relative, must not start with `/` or `~`, and must have no `..` component" before the symlink walk (`SKILL.md:63-64`).

**Evidence:** `skills/dev-cycle/SKILL.md:61-70`, commit 1ae9b21 (diff of `skills/dev-cycle/SKILL.md`)

---

## Claim 25: Commit 1f36885: "step 2 accepts the number or the word (a bare "[2]" was consumed with no effect)"

**Location:** commit 1f36885 (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the before and after text of step 2; does not establish how an agent treats near-forms.

Before: ""keep" sets `Kept: <today>`; "drop" closes the brief as in 1; any other answer changes nothing. Either way add the ID to `Applied:`" (`git show 074164b:skills/dev-cycle/SKILL.md:235-236`), so "[2]" was consumed with no effect, as the commit says. After, the accepted forms are the bracketed tokens "[1]"/"[2]" and the words (`SKILL.md:238-239`). "The number" is precise only for the bracketed form. An unbracketed `Q-NNN: 2` still falls under "any other answer changes nothing" and is still recorded on `Applied:`, so it is consumed with no effect, the same failure one notation over. Precise version: "accepts "[1]"/"[2]" or the word". **Wording**, with a narrow behavioral residue if a user omits the brackets.

**Evidence:** `skills/dev-cycle/SKILL.md:236-241`, `git show 074164b:skills/dev-cycle/SKILL.md` lines 235-236

---

## Claim 26: Commit 1f36885: "Briefs live in docs/working/briefs/ ("handoff" already names RPI's stop notes)"

**Location:** commit 1f36885 (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers RPI's use of "handoff" for its stop notes; does not establish other uses of the word.

RPI: "If ending mid-task, a handoff doc exists in `docs/working/handoff-{topic}.md`" (`workflows/research-plan-implement.md:470`) and "#### Session handoff (optional)" (`:472`), plus the debugging handoff `docs/working/handoff-diagnosis-*.md` (`:23`).

**Evidence:** `workflows/research-plan-implement.md:23`, `workflows/research-plan-implement.md:470-474`

---

## Claim 27: Commit 1f36885: "questions.sh init runs in step 1 on the cycle branch, not before it; step 1 drops the redundant index after archive."

**Location:** commit 1f36885 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the text move and the index removal; archive's reindex itself is executed in Claim 15.

The step 0 text "If the repo has no `docs/working/questions.md`, run `~/.claude/scripts/questions.sh init` first" is gone; step 0 now defers ("step 1 creates it", `SKILL.md:101-102`). Step 1 says "init now, on the cycle branch" (`:125-126`) and "`questions.sh archive` (it also reindexes)" with no separate `index` (`:129`). `cmd_archive` calls `cmd_index` (`scripts/questions.sh:393`).

**Evidence:** `skills/dev-cycle/SKILL.md:94-102`, `skills/dev-cycle/SKILL.md:125-130`, `scripts/questions.sh:374-395`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`scripts/dev-cycle.sh:207-209`, `:214`): **behavioral.** The one-walk map omits merge commits' own changes (no `--diff-merges`). A record last changed in a merge gets an older date, and one added in a merge shows "never, uncommitted", where per-file `git log -1` gave the merge date. Probe: 2 of 8 records differ. This repo's 32 records match.
- **Claim 8** (`scripts/dev-cycle.sh:209-210`, `:223`): **behavioral.** git also quotes names containing `"` or `\`. Those miss the map, skip the `[[:cntrl:]]`-only fallback, and print "never, uncommitted". Probe: both such records differ from the old rule.

### Stale
- None.

### Mostly Accurate
- **Claim 4** (`scripts/dev-cycle.sh:12-14`; commit "describes the default window exactly"): **wording** (pre-existing narrow behavioral residue). An impossible-date record name (`cycle-2026-02-30.md`) becomes the default and stops the digest with "--since must be a real YYYY-MM-DD date" instead of falling back to 14 days.
- **Claim 12** (`skills/dev-cycle/SKILL.md:61-67`): **behavioral, low.** The rule is complete for every write and for settings rows, but (a) a brief link is not required to be under `docs/working/briefs/`, so "Status: closed" can be written into any plain in-repo file a roadmap link names, and (b) step 4's repo-text paths (cited plans and tests) are outside the rule's list and get no lexical or symlink check.
- **Claim 25** (commit 1f36885): **wording.** "Accepts the number" means the bracketed "[1]"/"[2]" only. An unbracketed "2" is still consumed with no effect.

### Unverifiable
- **Claim 22** (commit 723c242): the 200k-commit / ~141-record timing comes from the performance review and was not re-measured.

---

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass17.md`. It has the required first line, the header fields (including `**Replication:** k=1 (loop pass, decision 031)`), the seven mandatory per-claim fields plus `**Legibility-target:**`, and the attention summary.

Most of the round's aims hold:
- **Option parser:** every form behaves as stated.
- **Section 7:** counts any file under skills/ or workflows/, including quoted names.
- **Section 3:** prints "Open by route: none" when nothing is open.
- **New skip checks:** both list a non-plain input in section 8.
- **Tests and shellcheck:** 23/23 pass and shellcheck is clean.
- **Path rule:** restored, and complete for every write the skill makes.
- **Keep-or-drop answers:** the bracketed numbers work.
- **questions.sh:** the init and archive wording matches its behavior.
- **briefs/ rename:** complete.

The section 2 date map is not equivalent to per-file `git log -1` (brief item 1). It drops merge-made changes and names quoted for `"` or `\`. Both are behavioral and Incorrect, though this repo's own output is unchanged. An uncommitted edit that appeared in A's worktree during this run appears to target both; it is not verdicted here. Not committed, per the brief.
