#!/usr/bin/env bash
# Self-discovering repo health check.
# Validates repo integrity by globbing for skills, workflows, fixtures, and
# shell scripts rather than hardcoding file lists.
#
# Usage:
#   scripts/health-check.sh
#
# No arguments or options. Exits 0 if all checks pass, non-zero otherwise.
#
# Environment:
#   HEALTH_CHECK_SKILLS_DIR  Directory scanned for skill files (checks 1, 9, 12, 13).
#                            Defaults to "$REPO_ROOT/skills". Test-only seam:
#                            test/scripts/health-check.bats points it at a
#                            copy under $BATS_TEST_TMPDIR so its broken-skill
#                            fixtures are never written into the real skills/
#                            (which every consuming project links and loads).
#                            The directory's basename must be "skills" —
#                            extract_skill_name keys on the /skills/ path part.
#   HEALTH_CHECK_SKIP_BATS   When 1, check 5 is skipped with a warning. Set by
#                            check 5 itself for the runner it launches, so the
#                            health-check.bats suite cannot recurse into the
#                            full suite; test/scripts/health-check.bats also
#                            sets it for its own runs.
#   HEALTH_CHECK_RUN_TESTS   Test-only seam: the runner check 5 invokes.
#                            Defaults to "$REPO_ROOT/scripts/run-tests.sh".
#
# Checks:
#   1. Skill YAML frontmatter parses correctly (name + description present)
#   2. Workflow cross-references in CLAUDE.md/AGENTS.md/GEMINI.md resolve
#   3. CLAUDE.md/AGENTS.md/GEMINI.md reference the same workflows and skills
#   4. All test fixtures have corresponding expected-verdicts entries
#   5. BATS tests pass: run-tests.sh --fast, then --slow only if fast is green
#   6. shellcheck passes on all .sh/.bash files
#   7. Workflow value-justification frontmatter is present
#   8. Hook scripts in hooks/ are executable, and are wired into the live
#      settings.json with their targets present (decision 023)
#   9. Skill test-fixture coverage report (soft warning, not a gate)
#  10. Feature integration: si-functions.sh orphan detection (soft warning)
#  11. Document freshness: flag stale spikes, onboarding and thoughts docs (soft warning)
#  12. Persona freshness: flag persona critique skills last sampled >~6 months ago
#  13. MD file semantic divergence: diff CLAUDE.md/AGENTS.md/GEMINI.md (soft warning)
#  14. Running-questions doc: entry grammar, unique ids, index freshness (gate)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${HEALTH_CHECK_SKILLS_DIR:-$REPO_ROOT/skills}"

# The global instructions file lives under global-instructions/ rather than the
# repo root: at the root, Claude Code loads it a second time as this project's
# own instructions on top of the ~/.claude copy the image links (prompt audit
# 2026-09-11, F1). devcontainer-config/install.sh stages it to the payload root,
# so the installed layout is unchanged — only the source path moved.
GLOBAL_MD="global-instructions/CLAUDE.md"
FAIL=0

# shellcheck source=lib/log-format.sh
source "$REPO_ROOT/scripts/lib/log-format.sh"
# shellcheck source=lib/md-utils.sh
source "$REPO_ROOT/scripts/lib/md-utils.sh"
# shellcheck source=lib/skill-paths.sh
source "$REPO_ROOT/scripts/lib/skill-paths.sh"

pass() { green "  ✓ $*"; }
fail() { red   "  ✗ $*"; FAIL=1; }
warn() { yellow "  ⚠ $*"; }
section() { echo; bold "── $* ──"; }

# Emit canonical skill markdown file paths, one per line, supporting both
# layouts: flat (skills/<name>.md) and directory (skills/<name>/SKILL.md).
# The directory form is the layout Claude Code's skill registry actually
# picks up; the flat form is legacy and not auto-registered. Glob both so
# migrations don't silently drop skills from validation.
discover_skill_files() {
    local skills_dir="$SKILLS_DIR"
    [[ -d "$skills_dir" ]] || return 0
    local f
    for f in "$skills_dir"/*.md; do
        [[ -f "$f" ]] && echo "$f"
    done
    for f in "$skills_dir"/*/SKILL.md; do
        [[ -f "$f" ]] && echo "$f"
    done
}

# Map a skill file path to its canonical skill name. Both layouts collapse
# to the same name:
#   skills/foo.md        -> foo
#   skills/foo/SKILL.md  -> foo
# Thin wrapper over extract_skill_name in scripts/lib/skill-paths.sh — kept
# under this name to avoid churning the rest of the script.
skill_name_from_path() {
    extract_skill_name "$1"
}

# ── 1. Skill YAML frontmatter ──────────────────────────────────────────────

check_skill_frontmatter() {
    section "Skill YAML frontmatter"
    local count=0
    local drift_count=0
    local skill
    while IFS= read -r skill; do
        count=$((count + 1))
        local basename
        basename="$(skill_name_from_path "$skill")"

        local yaml
        yaml="$(extract_yaml_frontmatter "$skill")"

        if [[ -z "$yaml" ]]; then
            fail "$basename: no YAML frontmatter found"
            drift_count=$((drift_count + 1))
            continue
        fi

        local file_ok=true

        # Check required fields: name, description. Not `when`: Claude Code's
        # skill loader ignores it and triggers on `description` alone
        # (guides/skill-format-audit.md F1), so requiring it enforced a field
        # nobody reads.
        if ! echo "$yaml" | grep -qE '^name:'; then
            fail "$basename: missing 'name' field"
            file_ok=false
        fi
        if ! echo "$yaml" | grep -qE '^description:'; then
            fail "$basename: missing 'description' field"
            file_ok=false
        fi

        # Check description is non-empty and multi-word.
        # Collect the description value: inline text after "description:" plus
        # any continuation lines (indented or folded with >).
        local desc_text
        desc_text="$(echo "$yaml" | sed -n '/^description:/,/^[a-z]/{/^description:/{ s/^description:[[:space:]>]*//; p; d; }; /^[a-z]/d; p; }' | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        if [[ -z "$desc_text" ]]; then
            fail "$basename: 'description' is empty"
            file_ok=false
        elif [[ $(echo "$desc_text" | wc -w) -lt 2 ]]; then
            fail "$basename: 'description' should be multi-word (got: '$desc_text')"
            file_ok=false
        fi

        # Check for unknown top-level keys.
        # allowed_keys reflects the conventions currently in use across skills:
        # name/description/when are required; the rest are optional design
        # metadata or dependency declarations.
        local allowed_keys="name description when requires persona-last-sampled lens non-goals adaptation-latitude"
        local unknown_keys
        unknown_keys="$(echo "$yaml" | grep -oE '^[a-zA-Z_-]+:' | sed 's/://' | while read -r key; do
            local found=false
            for allowed in $allowed_keys; do
                if [[ "$key" == "$allowed" ]]; then
                    found=true
                    break
                fi
            done
            if ! $found; then
                echo "$key"
            fi
        done | tr '\n' ' ' | sed 's/ *$//')"
        if [[ -n "$unknown_keys" ]]; then
            fail "$basename: unknown top-level key(s): $unknown_keys"
            file_ok=false
        fi

        # Check requires entries are consistently formatted. The schema permits
        # either an object form (`- name: …` + `description: …`) for skill
        # dependencies the orchestrator can resolve, or a bare-string list for
        # informational preconditions. Mixing the two within one block is the
        # only real bug we flag.
        if echo "$yaml" | grep -qE '^requires:'; then
            local req_block bare_entries name_entries
            req_block="$(echo "$yaml" | sed -n '/^requires:/,/^[a-z]/{/^requires:/d; /^[a-z]/d; p;}')"
            bare_entries="$(echo "$req_block" | grep -E '^[[:space:]]*-[[:space:]]' \
                | grep -vE '^[[:space:]]*-[[:space:]]+name:' || true)"
            name_entries="$(echo "$req_block" | grep -E '^[[:space:]]*-[[:space:]]+name:' || true)"
            if [[ -n "$bare_entries" && -n "$name_entries" ]]; then
                fail "$basename: 'requires' mixes object-form and bare-string entries — pick one format"
                file_ok=false
            fi
        fi

        if $file_ok; then
            pass "$basename"
        else
            drift_count=$((drift_count + 1))
        fi
    done < <(discover_skill_files)
    if [[ $count -eq 0 ]]; then
        fail "No skill files found in skills/"
    else
        pass "$count skill(s) checked"
        if [[ $drift_count -gt 0 ]]; then
            warn "$drift_count file(s) with frontmatter issues (structural drift detected)"
        fi
    fi
}

# ── 2. Workflow cross-references resolve ────────────────────────────────────

# Extract workflow filenames referenced in a markdown file.
# Handles three syntaxes:
#   CLAUDE.md:  **research-plan-implement.md**
#   AGENTS.md:  **@./workflows/research-plan-implement.md**
#   GEMINI.md:  **research-plan-implement.md**
extract_workflows() {
    local file="$1"
    # Allow ** or ` as the delimiter. CLAUDE.md uses backticks for all filenames
    # (so the result is filtered against workflows/ in the caller); AGENTS.md
    # and GEMINI.md use bold. `|| true` keeps the function quiet under
    # set -o pipefail when grep finds no matches.
    { grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$file" || true; } \
        | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' \
        | sort -u
}

check_workflow_crossrefs() {
    section "Workflow cross-references"
    for mdfile in "$GLOBAL_MD" AGENTS.md GEMINI.md; do
        local path="$REPO_ROOT/$mdfile"
        [[ -f "$path" ]] || { warn "$mdfile not found, skipping"; continue; }

        local workflows
        workflows="$(extract_workflows "$path")"
        if [[ -z "$workflows" ]]; then
            warn "$mdfile: no workflow references found"
            continue
        fi

        local all_ok=true
        while IFS= read -r wf; do
            if [[ ! -f "$REPO_ROOT/workflows/$wf" ]]; then
                fail "$mdfile references $wf but workflows/$wf does not exist"
                all_ok=false
            fi
        done <<< "$workflows"
        if $all_ok; then
            pass "$mdfile: all workflow references resolve"
        fi
    done
}

# ── 3. MD files reference the same workflows and skills ─────────────────────

check_md_consistency() {
    section "MD file consistency (workflows)"

    local -a files=()
    local -A workflow_sets=()

    for mdfile in "$GLOBAL_MD" AGENTS.md GEMINI.md; do
        local path="$REPO_ROOT/$mdfile"
        # All three are tracked files. A missing one used to `continue` silently,
        # which degraded this check to an AGENTS-vs-GEMINI comparison that
        # agents-gemini-sync.bats already guarantees — and still printed a pass.
        # Fail instead, so a rename is loud (code review 2026-09-12, A12).
        [[ -f "$path" ]] || { fail "$mdfile not found — MD consistency cannot be checked"; continue; }
        files+=("$mdfile")
        workflow_sets["$mdfile"]="$(extract_workflows "$path" | tr '\n' '|')"
    done

    if [[ ${#files[@]} -lt 2 ]]; then
        warn "Fewer than 2 MD files found, skipping consistency check"
        return
    fi

    local reference="${workflow_sets[${files[0]}]}"
    local consistent=true
    for mdfile in "${files[@]:1}"; do
        if [[ "${workflow_sets[$mdfile]}" != "$reference" ]]; then
            consistent=false
            # Show the diff
            local ref_list other_list
            ref_list="$(echo "$reference" | tr '|' '\n' | grep -v '^$' | sort)"
            other_list="$(echo "${workflow_sets[$mdfile]}" | tr '|' '\n' | grep -v '^$' | sort)"

            local only_in_ref only_in_other
            only_in_ref="$(comm -23 <(echo "$ref_list") <(echo "$other_list"))"
            only_in_other="$(comm -13 <(echo "$ref_list") <(echo "$other_list"))"

            if [[ -n "$only_in_ref" ]]; then
                fail "In ${files[0]} but not $mdfile: $only_in_ref"
            fi
            if [[ -n "$only_in_other" ]]; then
                fail "In $mdfile but not ${files[0]}: $only_in_other"
            fi
        fi
    done
    if $consistent; then
        pass "All MD files reference the same workflows"
    fi
}

# ── 4. Test fixtures ↔ expected-verdicts ────────────────────────────────────

check_fixture_verdicts() {
    section "Fixture ↔ expected-verdicts coverage"

    for skill_dir in "$REPO_ROOT"/test/skills/*/; do
        [[ -d "$skill_dir/fixtures" ]] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        local verdicts_file="$skill_dir/expected-verdicts.bash"

        if [[ ! -f "$verdicts_file" ]]; then
            fail "$skill_name: has fixtures/ but no expected-verdicts.bash"
            continue
        fi

        local all_ok=true
        # A fixture is a file, or a directory for tree-mode runners
        # (test/skills/generate-reports.bash: self-eval, divergent-design).
        for fixture in "$skill_dir"/fixtures/*; do
            [[ -f "$fixture" || -d "$fixture" ]] || continue
            local fixture_name
            fixture_name="$(basename "$fixture")"

            # Check that fixture appears as a key in EXPECTED_VERDICT
            if ! grep -qF "\"$fixture_name\"" "$verdicts_file"; then
                fail "$skill_name: fixture $fixture_name has no expected-verdicts entry"
                all_ok=false
            fi
        done

        # Reverse check: verdicts that reference non-existent fixtures
        local verdict_keys
        verdict_keys="$(grep -oP 'EXPECTED_VERDICT\["\K[^"]+' "$verdicts_file" | sort -u)"
        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            if [[ ! -e "$skill_dir/fixtures/$key" ]]; then
                fail "$skill_name: expected-verdicts references $key but fixture does not exist"
                all_ok=false
            fi
        done <<< "$verdict_keys"

        if $all_ok; then
            pass "$skill_name: all fixtures have verdicts and vice versa"
        fi
    done
}

# ── 5. BATS tests ──────────────────────────────────────────────────────────
#
# Runs every tagged suite through scripts/run-tests.sh, fast first and slow
# second (Q-023). The fast set is a blocking pre-gate: if it is red, the slow
# set is not run at all, so a broken tree fails in the fast-suite time rather
# than after the multi-minute slow set. The gate fails if either set is red.
#
# Before Q-023 this gate ran only test/skills/ and test/hooks/, so a green
# health-check said nothing about the ~40 suites under test/ and test/scripts/
# (link-claude-home-wiring.bats among them). Report gating (suites tagged
# "# @needs-reports <skill>" run only when that skill has generated reports) is
# owned by run-tests.sh; this gate only surfaces how many it left out, as a
# warning, via RUN_TESTS_NOT_RUN_FILE.
#
# Recursion guard: test/scripts/health-check.bats is a slow suite that runs
# this script. Without a guard, gate 5 -> run-tests --slow -> health-check.bats
# -> health-check.sh -> gate 5 -> ... never terminates. The runner is invoked
# with HEALTH_CHECK_SKIP_BATS=1 in its environment, and a health-check that
# sees that variable skips this gate (with a warning, never a pass).
#
# HEALTH_CHECK_RUN_TESTS is a test-only seam naming the runner, so
# test/scripts/health-check.bats can check the fast-then-slow ordering with a
# stub instead of re-running the real suites.

check_bats() {
    section "BATS tests"

    if [[ "${HEALTH_CHECK_SKIP_BATS:-}" == 1 ]]; then
        warn "HEALTH_CHECK_SKIP_BATS=1 — BATS gate skipped (nested run; the outer run gates the suites)"
        return
    fi

    if ! command -v bats &>/dev/null; then
        warn "bats not installed, skipping"
        return
    fi

    local runner="${HEALTH_CHECK_RUN_TESTS:-$REPO_ROOT/scripts/run-tests.sh}"
    # The runner writes how many report-dependent suites it gated out (no
    # generated reports for their skill) to RUN_TESTS_NOT_RUN_FILE. Those did
    # not run, so they are reported as a warning with their count, and the
    # pass lines say the passing set excludes them.
    local nr_dir fast_nr slow_nr
    nr_dir="$(mktemp -d)"

    if ! HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast; then
        fail "Fast BATS suites failed — slow suites not run (fix fast first)"
        rm -rf "$nr_dir"
        return
    fi
    fast_nr="$(_not_run_count "$nr_dir/fast")"
    pass "Fast BATS suites passed$(_not_run_note "$fast_nr")"

    if HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/slow" "$runner" --slow; then
        slow_nr="$(_not_run_count "$nr_dir/slow")"
        pass "Slow BATS suites passed$(_not_run_note "$slow_nr")"
    else
        slow_nr="$(_not_run_count "$nr_dir/slow")"
        fail "Slow BATS suites failed"
    fi
    rm -rf "$nr_dir"

    if (( fast_nr + slow_nr > 0 )); then
        warn "$((fast_nr + slow_nr)) report-dependent BATS suite(s) NOT RUN — no generated reports for their skill (listed in the runner output above; generate with test/skills/generate-reports.bash <skill>)"
    fi
}

# _not_run_count <file>: the gated-out count run-tests.sh wrote, or 0 when it
# wrote none (an older or stub runner) or wrote something that is not a number.
_not_run_count() {
    local n=""
    [[ -f "$1" ]] && n="$(tr -d '[:space:]' < "$1")"
    [[ "$n" =~ ^[0-9]+$ ]] || n=0
    printf '%s' "$n"
}

# _not_run_note <count>: suffix for a pass line, so it never reads as if the
# gated-out suites had run.
_not_run_note() {
    (( $1 > 0 )) && printf ' (excluding %s report-dependent suite(s) not run)' "$1"
    return 0
}

# ── 6. shellcheck ───────────────────────────────────────────────────────────

check_shellcheck() {
    section "shellcheck"

    if ! command -v shellcheck &>/dev/null; then
        warn "shellcheck not installed, skipping"
        return
    fi

    # Skip .claude/ as well as .git/: the self-improvement loop parks nested git
    # worktrees under .claude/worktrees/ (gitignored). Those are whole second
    # copies of this repo, so linting them both double-reports every finding and
    # makes the result depend on which worktrees happen to be lying around
    # locally — a stale one keeps failing the gate long after the branch is gone.
    #
    # Both prunes are ANCHORED at $REPO_ROOT. An unanchored '*/.claude/*' is
    # matched against the absolute path, so when the checkout ITSELF sits under a
    # .claude/ dir — which is exactly where the worktrees above live — it excludes
    # every file in the repo, and the gate reports green having linted nothing.
    # external/ holds vendored third-party checkouts (their lint findings are not
    # ours to fix) and archive/ holds retired code kept for the record (the
    # 2026-08-20 benchmark archival moved scripts there precisely to take them
    # out of the live gates — run-tests.sh stopped collecting them; this gate
    # must too).
    local shell_files=()
    while IFS= read -r -d '' f; do
        shell_files+=("$f")
    done < <(find "$REPO_ROOT" -type f \( -name '*.sh' -o -name '*.bash' \) \
        -not -path "$REPO_ROOT/.git/*" -not -path "$REPO_ROOT/.claude/*" \
        -not -path "$REPO_ROOT/external/*" -not -path "$REPO_ROOT/archive/*" -print0)

    # Also include .bats files — they're bash
    while IFS= read -r -d '' f; do
        shell_files+=("$f")
    done < <(find "$REPO_ROOT" -type f -name '*.bats' \
        -not -path "$REPO_ROOT/.git/*" -not -path "$REPO_ROOT/.claude/*" \
        -not -path "$REPO_ROOT/external/*" -not -path "$REPO_ROOT/archive/*" -print0)

    # A zero-file scan is a broken discovery, not a clean repo: this gate exists
    # in a repo that is mostly shell. Fail rather than pass vacuously.
    if [[ ${#shell_files[@]} -eq 0 ]]; then
        fail "No shell files found — the discovery glob is broken, not the repo clean"
        return
    fi

    local all_ok=true
    for f in "${shell_files[@]}"; do
        local relpath="${f#"$REPO_ROOT"/}"
        # -x follows sourced files; -e SC1091 skips missing sourced files;
        # -s bash sets the shell for .bats files lacking a shebang;
        # -S warning ignores info-level findings (SC2016 et al) so the
        # gate trips only on genuine warnings or errors.
        if shellcheck -x -e SC1091 -s bash -S warning "$f" 2>/dev/null; then
            pass "$relpath"
        else
            fail "$relpath"
            all_ok=false
        fi
    done
}

# ── 7. Workflow value-justification frontmatter ───────────────────────────

check_workflow_value_justification() {
    section "Workflow value-justification"

    local count=0
    local missing=0

    for wf in "$REPO_ROOT"/workflows/*.md; do
        [[ -f "$wf" ]] || continue
        count=$((count + 1))
        local name
        name="$(basename "$wf")"

        # Check for YAML frontmatter with value-justification field
        # Frontmatter must start on line 1 with --- and contain value-justification: before closing ---
        local value=""

        if head -1 "$wf" | grep -q '^---$'; then
            value="$(get_frontmatter_field "$wf" value-justification)"
        fi

        if [[ -n "$value" ]]; then
            pass "$name: value-justification present"
        else
            warn "$name: missing or empty value-justification in frontmatter"
            missing=$((missing + 1))
        fi
    done

    if [[ $count -eq 0 ]]; then
        warn "No workflow files found in workflows/"
    else
        if [[ $missing -eq 0 ]]; then
            pass "$count workflow(s) checked — all have value-justification"
        else
            warn "$count workflow(s) checked — $missing missing value-justification"
        fi
    fi
}

# ── 8. Hook scripts are executable ─────────────────────────────────────────

check_hook_permissions() {
    section "Hook script permissions"

    local count=0
    for hook in "$REPO_ROOT"/hooks/*.sh; do
        [[ -f "$hook" ]] || continue
        count=$((count + 1))
        local name
        name="$(basename "$hook")"

        if [[ -x "$hook" ]]; then
            pass "$name is executable"
        else
            fail "$name is not executable (chmod +x to fix)"
        fi
    done

    if [[ $count -eq 0 ]]; then
        warn "No hook scripts found in hooks/"
    else
        pass "$count hook(s) checked"
    fi
}

# ── 8b. Hooks are actually wired into the live settings.json ───────────────
#
# The recurring failure this repo keeps hitting is not a broken hook, it is a
# hook that is present, looks installed, and does nothing (decisions 022, 023,
# and 023 amendment A). Executable-bit checks do not catch any of it. This
# check compares hooks/wiring.json against the settings.json the running
# session actually reads, and confirms each command's target exists.
#
# Findings here are WARNINGS, not failures: they report a stale *environment*
# (an image built before the current wiring.json, a volume that predates a
# change), not a defect in the repo, and the fix is install.sh + bless +
# rebuild on the host rather than an edit here. The repo-side invariants —
# every wiring command points at a real hook, the deny rules the guard depends
# on are declared — are hard-gated by test/link-claude-home-wiring.bats, which
# check 5 runs (it is a slow suite, run once the fast suites are green).

check_hook_wiring() {
    section "Hook wiring (live settings.json)"

    local wiring="$REPO_ROOT/hooks/wiring.json"
    local settings="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

    if [[ ! -f "$wiring" ]]; then
        warn "hooks/wiring.json not found — nothing to compare against"
        return
    fi
    if ! command -v jq >/dev/null 2>&1; then
        warn "jq not found — skipping wiring comparison"
        return
    fi
    if [[ ! -f "$settings" ]]; then
        warn "No settings.json at $settings — not running in a wired container?"
        return
    fi

    local missing=0 inert=0 total=0 cmd resolved
    while IFS= read -r cmd; do
        [[ -n "$cmd" ]] || continue
        total=$((total + 1))
        if ! jq -e --arg c "$cmd" \
            '[.hooks[]?[]?.hooks[]? | select(.command == $c)] | length > 0' \
            "$settings" >/dev/null 2>&1; then
            warn "not wired: $cmd"
            missing=$((missing + 1))
            continue
        fi
        # Wired is not the same as working: the command's target has to exist.
        resolved="${cmd##* }"
        if [[ ! -e "$resolved" ]]; then
            warn "wired but target missing: $resolved"
            inert=$((inert + 1))
        fi
    done < <(jq -r '.hooks[][].hooks[].command' "$wiring" \
             | sed "s#{{CLAUDE_DIR}}#${CLAUDE_CONFIG_DIR:-$HOME/.claude}#g")

    if [[ $missing -eq 0 && $inert -eq 0 ]]; then
        pass "$total wired hook command(s), all targets present"
    fi

    # The guard hook's HARD tier defers to permissions.deny for Edit/Write, so
    # a missing deny rule silently disarms it (decision 023 amendment B).
    local want_deny have_deny
    want_deny=$(jq -r '.permissions.deny // [] | length' "$wiring")
    have_deny=$(jq -r --arg d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" \
        '[.permissions.deny[]? | select(. != null)] | length' "$settings" 2>/dev/null || echo 0)
    if [[ "$want_deny" -gt 0 && "$have_deny" -eq 0 ]]; then
        warn "permissions.deny is empty — guard-trusted-writes.py's HARD tier is a no-op for Edit/Write"
    elif [[ "$want_deny" -gt 0 ]]; then
        pass "permissions.deny present ($have_deny rule(s))"
    fi
}

# ── 9. Skill test-fixture coverage ────────────────────────────────────────

check_skill_fixture_coverage() {
    section "Skill test-fixture coverage"

    local total=0
    local covered=0
    local uncovered_skills=()
    local skill
    while IFS= read -r skill; do
        total=$((total + 1))

        local skill_name
        skill_name="$(skill_name_from_path "$skill")"

        # No per-skill lines: missing fixtures is a standing property of the
        # repo, not an event, so printing one warning per skill buried the
        # other checks (24 of 29 warnings; see
        # docs/working/triage-2026-09-17-backlog.md §1.1). The summary below
        # carries the same facts in two lines.
        local fixture_dir="$REPO_ROOT/test/skills/$skill_name/fixtures"
        # code-review has no fixture generator by design: its suites grade a
        # real rubric via REPORT_PATH or a golden (test/skills/code-review-
        # format.bats header). Listing it made this warning un-clearable.
        if [[ "$skill_name" == "code-review" ]]; then
            covered=$((covered + 1))
        elif [[ -d "$fixture_dir" ]] && ls "$fixture_dir"/* &>/dev/null 2>&1; then
            covered=$((covered + 1))
        else
            uncovered_skills+=("$skill_name")
        fi
    done < <(discover_skill_files)

    local uncovered=${#uncovered_skills[@]}
    if [[ $total -eq 0 ]]; then
        warn "No skill files found in skills/"
    else
        echo
        bold "  Coverage: $covered/$total skills have test fixtures ($uncovered without)"
        if [[ $uncovered -gt 0 ]]; then
            warn "Skills lacking fixtures: ${uncovered_skills[*]}"
        fi
    fi
}

# ── 10. Feature integration check (si-functions.sh) ───────────────────────
# A function is considered "wired in" if it is called from any entry-point
# script OR from another function inside si-functions.sh (i.e., reached
# transitively). Only functions with no caller at all are flagged as orphans.

check_feature_integration() {
    section "Feature integration (si-functions.sh)"

    local lib_file="$REPO_ROOT/scripts/lib/si-functions.sh"
    if [[ ! -f "$lib_file" ]]; then
        warn "si-functions.sh not found, skipping"
        return
    fi

    # Extract top-level function names defined in si-functions.sh
    local functions=()
    while IFS= read -r fname; do
        [[ -n "$fname" ]] && functions+=("$fname")
    done < <(grep -oE '^[a-zA-Z_][a-zA-Z_0-9]*\s*\(\)' "$lib_file" | sed 's/[[:space:]]*()$//')

    if [[ ${#functions[@]} -eq 0 ]]; then
        warn "No functions found in si-functions.sh"
        return
    fi

    # Concatenate every entry-point script's contents once. Greps then scan
    # this single buffer for each function name instead of spawning
    # F × S grep processes (F = function count, S = entry scripts).
    local entry_buffer
    entry_buffer=$(find "$REPO_ROOT/scripts" -type f -name '*.sh' -not -path '*/.git/*' \
                   ! -wholename "$lib_file" -exec cat {} +)

    # The library buffer is read once too. The sibling-helper check excludes
    # the function's own definition line, so strip those lines up front.
    local lib_buffer
    lib_buffer=$(grep -vE '^[a-zA-Z_][a-zA-Z_0-9]*[[:space:]]*\(\)' "$lib_file")

    local orphan_count=0
    local total=${#functions[@]}
    local orphan_names=()

    for fname in "${functions[@]}"; do
        local found_in_entry=false
        if grep -qE "(^|[^a-zA-Z_])${fname}([^a-zA-Z_0-9]|$)" <<< "$entry_buffer"; then
            found_in_entry=true
        fi

        # If no entry-point caller, check for intra-library calls — helpers
        # used only by sibling functions in si-functions.sh are still wired in
        # transitively when their caller is reached from an entry point.
        local found_in_lib=false
        if ! $found_in_entry; then
            if grep -qE "(^|[^a-zA-Z_])${fname}([^a-zA-Z_0-9]|$)" <<< "$lib_buffer"; then
                found_in_lib=true
            fi
        fi

        if $found_in_entry; then
            pass "$fname: called from entry point"
        elif $found_in_lib; then
            pass "$fname: called from sibling helper in $(basename "$lib_file")"
        else
            warn "$fname: not called from any entry-point script (orphan)"
            orphan_count=$((orphan_count + 1))
            orphan_names+=("$fname")
        fi
    done

    # Instrumentation for hypothesis evaluation
    echo
    bold "  Feature integration: $((total - orphan_count))/$total functions called from entry points"
    if [[ $orphan_count -gt 0 ]]; then
        warn "Orphaned functions ($orphan_count): ${orphan_names[*]}"
        warn "These may be intentionally library-only, or may indicate unfinished integration."
    else
        pass "All si-functions.sh functions are called from at least one entry point"
    fi
}

# ── 11. Document freshness (spikes + onboarding + thoughts docs) ─────────

# _freshness_field <name> <file>: the value of a "Last verified" / "Relevant
# paths" field outside code fences. Accepts the three spellings the docs use:
# **Name:** value · Name: value · `Name`: value.
_freshness_field() {
    awk -v name="$1" '
        /^```/ { in_code = !in_code; next }
        in_code { next }
        {
            line = $0
            gsub(/[*`]/, "", line)
            if (index(line, name ":") == 1) {
                sub("^" name ":[[:space:]]*", "", line)
                print line
                exit
            }
        }
    ' "$2"
}

check_doc_freshness() {
    section "Document freshness (spikes + onboarding + thoughts)"

    local checked=0
    local stale=0
    local fresh=0
    local missing_fields=0

    # Collect candidate docs: docs/spikes/*.md and docs/working/onboarding-*.md
    local docs=()
    for f in "$REPO_ROOT"/docs/spikes/*.md; do
        [[ -f "$f" ]] && docs+=("$f")
    done
    for f in "$REPO_ROOT"/docs/working/onboarding-*.md; do
        [[ -f "$f" ]] && docs+=("$f")
    done
    # docs/thoughts/ opts in: the global instructions list shared thoughts as
    # freshness-tracked, but only the ones that carry the fields are checked,
    # so a note without them is not a warning.
    for f in "$REPO_ROOT"/docs/thoughts/*.md; do
        [[ -f "$f" ]] || continue
        [[ -n "$(_freshness_field "Last verified" "$f")" ]] && docs+=("$f")
    done

    if [[ ${#docs[@]} -eq 0 ]]; then
        pass "No spike or onboarding docs found — nothing to check"
        return
    fi

    for doc in "${docs[@]}"; do
        local relpath="${doc#"$REPO_ROOT"/}"

        # First YYYY-MM-DD in the field; anything after it is commentary.
        local last_verified raw_verified
        raw_verified="$(_freshness_field "Last verified" "$doc")"
        last_verified="$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' <<< "$raw_verified" | head -1)"
        [[ -n "$raw_verified" && -z "$last_verified" ]] && last_verified="$raw_verified"

        # Path-like tokens only (contain / or a file extension); separators and
        # parenthetical commentary vary between docs.
        local relevant_paths
        relevant_paths="$(_freshness_field "Relevant paths" "$doc" \
            | grep -oE '[A-Za-z0-9_.-]*[/.][A-Za-z0-9_./-]*[A-Za-z0-9_/]' | tr '\n' ' ')"

        if [[ -z "$last_verified" || -z "$relevant_paths" ]]; then
            missing_fields=$((missing_fields + 1))
            warn "$relpath: missing freshness fields (Last verified / Relevant paths)"
            continue
        fi

        # Validate date format (YYYY-MM-DD)
        if ! [[ "$last_verified" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            warn "$relpath: 'Last verified' is not a valid date: $last_verified"
            missing_fields=$((missing_fields + 1))
            continue
        fi

        checked=$((checked + 1))

        # Split relevant_paths on commas and/or spaces into an array
        local -a paths=()
        IFS=', ' read -ra paths <<< "$relevant_paths"

        # Run git log --since against tracked paths
        local git_output
        git_output="$(git -C "$REPO_ROOT" log --oneline --since="$last_verified" -- "${paths[@]}" 2>/dev/null || true)"

        if [[ -n "$git_output" ]]; then
            stale=$((stale + 1))
            local commit_count
            commit_count="$(echo "$git_output" | wc -l)"
            warn "$relpath: STALE — $commit_count commit(s) to tracked paths since $last_verified"
        else
            fresh=$((fresh + 1))
            pass "$relpath: fresh (no changes to tracked paths since $last_verified)"
        fi
    done

    # Summary line for hypothesis evaluation
    echo
    bold "  Freshness: $checked checked, $fresh fresh, $stale stale, $missing_fields missing fields"
}

# ── 12. Persona freshness (last-sampled within ~6 months) ────────────────

check_persona_freshness() {
    section "Persona freshness (last-sampled within ~6 months)"

    # Skills carrying a 'persona-last-sampled: YYYY-MM-DD' frontmatter field
    # encode when their persona model was last calibrated against current
    # writings. Beyond ~6 months, the model may drift from the real persona.
    local stale_threshold_days=180
    local now_seconds
    now_seconds="$(date +%s)"

    local checked=0
    local fresh=0
    local stale=0
    local invalid=0

    local skill
    while IFS= read -r skill; do
        local basename
        basename="$(skill_name_from_path "$skill")"

        local last_sampled
        last_sampled="$(get_frontmatter_field "$skill" persona-last-sampled)"

        # Skill doesn't opt into freshness tracking — skip silently.
        [[ -z "$last_sampled" ]] && continue

        if ! [[ "$last_sampled" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            warn "$basename: persona-last-sampled is not a valid YYYY-MM-DD date: $last_sampled"
            invalid=$((invalid + 1))
            continue
        fi

        local sampled_seconds
        if ! sampled_seconds="$(date -d "$last_sampled" +%s 2>/dev/null)"; then
            warn "$basename: could not parse persona-last-sampled date: $last_sampled"
            invalid=$((invalid + 1))
            continue
        fi

        checked=$((checked + 1))
        local diff_days=$(( (now_seconds - sampled_seconds) / 86400 ))

        if (( diff_days > stale_threshold_days )); then
            warn "$basename: STALE — persona last sampled $diff_days days ago ($last_sampled, threshold $stale_threshold_days)"
            stale=$((stale + 1))
        else
            pass "$basename: fresh ($diff_days days since $last_sampled)"
            fresh=$((fresh + 1))
        fi
    done < <(discover_skill_files)

    echo
    if [[ $checked -eq 0 && $invalid -eq 0 ]]; then
        warn "No skill declares 'persona-last-sampled' — no personas tracked"
    else
        bold "  Persona freshness: $checked checked, $fresh fresh, $stale stale, $invalid invalid"
    fi
}

# ── 13. MD file semantic divergence ────────────────────────────────────────
# CLAUDE.md is consumed by Claude Code; AGENTS.md and GEMINI.md feed other
# agentic tools and can drift silently when CLAUDE.md is updated. This check
# diff-summarizes the three files (sections + skill references) to surface
# that drift. Soft warnings only — some divergence is intentional (e.g.,
# CLAUDE-specific Operating Modes), so the check exists for human review,
# not to gate on.

check_md_semantic_divergence() {
    section "MD file semantic divergence"

    # Build canonical skill list from both flat and dir-form skills to detect
    # references — discover_skill_files handles either layout.
    local -a known_skills=()
    local skill_file
    while IFS= read -r skill_file; do
        known_skills+=("$(skill_name_from_path "$skill_file")")
    done < <(discover_skill_files)

    local -a files=()
    local -A h2_set=()
    local -A h3_set=()
    local -A skill_set=()
    local -A line_count=()

    local mdfile path
    for mdfile in "$GLOBAL_MD" AGENTS.md GEMINI.md; do
        path="$REPO_ROOT/$mdfile"
        if [[ ! -f "$path" ]]; then
            warn "$mdfile not found, skipping"
            continue
        fi
        files+=("$mdfile")

        # || true guards against pipefail when grep finds no matches
        h2_set["$mdfile"]="$(grep -E '^## ' "$path" | sed 's/^## //' | sort -u || true)"
        h3_set["$mdfile"]="$(grep -E '^### ' "$path" | sed 's/^### //' | sort -u || true)"
        line_count["$mdfile"]="$(wc -l < "$path" | tr -d ' ')"

        local refs=""
        if [[ ${#known_skills[@]} -gt 0 ]]; then
            local skill
            for skill in "${known_skills[@]}"; do
                # Token-boundary match: skill name surrounded by non-word chars
                if grep -qE "(^|[^a-zA-Z0-9_-])${skill}([^a-zA-Z0-9_-]|$)" "$path"; then
                    refs+="${skill}"$'\n'
                fi
            done
        fi
        skill_set["$mdfile"]="$(printf '%s' "$refs" | sort -u)"
    done

    if [[ ${#files[@]} -lt 2 ]]; then
        warn "Fewer than 2 MD files found, skipping"
        return
    fi

    # Per-file summary line (always shown, informational)
    local h2c h3c skillc
    for mdfile in "${files[@]}"; do
        h2c="$(printf '%s\n' "${h2_set[$mdfile]}" | grep -c . || true)"
        h3c="$(printf '%s\n' "${h3_set[$mdfile]}" | grep -c . || true)"
        skillc="$(printf '%s\n' "${skill_set[$mdfile]}" | grep -c . || true)"
        echo "  $mdfile: ${line_count[$mdfile]} lines, $h2c H2 + $h3c H3 sections, $skillc skill ref(s)"
    done

    local divergence=0

    # 1) AGENTS.md and GEMINI.md should have identical section structure —
    #    they target different tools but carry the same content.
    if [[ -n "${h2_set[AGENTS.md]+x}" && -n "${h2_set[GEMINI.md]+x}" ]]; then
        if [[ "${h2_set[AGENTS.md]}" == "${h2_set[GEMINI.md]}" \
              && "${h3_set[AGENTS.md]}" == "${h3_set[GEMINI.md]}" ]]; then
            pass "AGENTS.md and GEMINI.md have identical section structure"
        else
            warn "AGENTS.md and GEMINI.md have diverging section structure — these should be kept in sync"
            divergence=$((divergence + 1))
        fi
    fi

    # 2) Section diff: CLAUDE.md vs each sibling. Renamed sections will
    #    appear on both sides — humans judge whether to align or accept.
    #
    # Some structural divergence is intentional: CLAUDE.md has Claude
    # Code-specific sections (Operating Modes, Session Hygiene, …) and
    # AGENTS.md/GEMINI.md split "Workflow & Skill Activation" into two
    # H2s. These known-acceptable names are listed below so the check
    # only flags unexpected drift. Add an entry only when the divergence
    # is by design — every name here is a thing we promised not to sync.
    # Newline-separated lists of section names whose absence from the
    # sibling (or from CLAUDE) is by design. Add an entry only when the
    # divergence is intentional — every name here is a thing we promised
    # not to sync. "Workflow & Skill Activation" maps to AGENTS/GEMINI's
    # split "Cross-project Workflows" + "Skills" pair.
    # Tool Preferences describes the Claude Code sandbox and allowlist, which the
    # AGENTS.md/GEMINI.md tools do not run under (triage 2026-09-17 §2.1, HC2).
    local expected_claude_only="Operating Modes
Review Artifacts
Session Hygiene
Tool Preferences (sandbox-aware)
Workflow & Skill Activation"
    local expected_sibling_only="Cross-project Workflows
Skills"

    local sibling only_claude only_sibling
    if [[ -n "${h2_set[$GLOBAL_MD]+x}" ]]; then
        for sibling in AGENTS.md GEMINI.md; do
            [[ -n "${h2_set[$sibling]+x}" ]] || continue
            only_claude="$(comm -23 <(printf '%s\n' "${h2_set[$GLOBAL_MD]}") <(printf '%s\n' "${h2_set[$sibling]}") | grep -v '^$' || true)"
            only_sibling="$(comm -13 <(printf '%s\n' "${h2_set[$GLOBAL_MD]}") <(printf '%s\n' "${h2_set[$sibling]}") | grep -v '^$' || true)"
            # Filter out intentionally-divergent section names.
            only_claude="$(grep -vxF "$expected_claude_only" <<< "$only_claude" | grep -v '^$' || true)"
            only_sibling="$(grep -vxF "$expected_sibling_only" <<< "$only_sibling" | grep -v '^$' || true)"
            if [[ -n "$only_claude" ]]; then
                warn "H2 sections in $GLOBAL_MD not in $sibling: $(echo "$only_claude" | tr '\n' '|' | sed 's/|/, /g; s/, $//')"
                divergence=$((divergence + 1))
            fi
            if [[ -n "$only_sibling" ]]; then
                warn "H2 sections in $sibling not in $GLOBAL_MD: $(echo "$only_sibling" | tr '\n' '|' | sed 's/|/, /g; s/, $//')"
                divergence=$((divergence + 1))
            fi
        done
    fi

    # 3) Skill references: CLAUDE.md vs each sibling — highest-signal diff
    #    because it points to specific skills whose mention hasn't propagated.
    if [[ -n "${skill_set[$GLOBAL_MD]+x}" ]]; then
        for sibling in AGENTS.md GEMINI.md; do
            [[ -n "${skill_set[$sibling]+x}" ]] || continue
            only_claude="$(comm -23 <(printf '%s\n' "${skill_set[$GLOBAL_MD]}") <(printf '%s\n' "${skill_set[$sibling]}") | grep -v '^$' || true)"
            only_sibling="$(comm -13 <(printf '%s\n' "${skill_set[$GLOBAL_MD]}") <(printf '%s\n' "${skill_set[$sibling]}") | grep -v '^$' || true)"
            if [[ -n "$only_claude" ]]; then
                warn "Skills referenced in $GLOBAL_MD but not $sibling: $(echo "$only_claude" | tr '\n' ' ' | sed 's/ $//')"
                divergence=$((divergence + 1))
            fi
            if [[ -n "$only_sibling" ]]; then
                warn "Skills referenced in $sibling but not $GLOBAL_MD: $(echo "$only_sibling" | tr '\n' ' ' | sed 's/ $//')"
                divergence=$((divergence + 1))
            fi
        done
    fi

    echo
    if [[ $divergence -eq 0 ]]; then
        pass "No semantic divergence detected across MD files"
    else
        bold "  $divergence divergence signal(s) detected"
        warn "AGENTS.md and GEMINI.md are not read by Claude Code — content updates in $GLOBAL_MD may drift silently"
    fi
}

# ── Run all checks ─────────────────────────────────────────────────────────

# ── 14. Running-questions structure ────────────────────────────────────────
# The running-questions doc is where autonomous work parks anything that needs
# the user, so an entry that drops out of the index is an ask that silently
# stops being asked. scripts/questions.sh check validates the entry grammar,
# id uniqueness and index freshness; this wires it in as a gate.
check_questions_doc() {
    section "Running questions"
    local out
    # questions.sh resolves docs/working/ from the caller's $PWD (so the
    # installed copy serves any project); pin it to this repo's files so the
    # gate checks the same doc wherever health-check is launched from.
    if out="$(QUESTIONS_LIVE="${QUESTIONS_LIVE:-$REPO_ROOT/docs/working/questions.md}" \
              QUESTIONS_ARCHIVE="${QUESTIONS_ARCHIVE:-$REPO_ROOT/docs/working/questions-archive.md}" \
              "$REPO_ROOT/scripts/questions.sh" check 2>&1)"; then
        echo "$out"
    else
        echo "$out"
        fail "questions doc: structure or index problems (see above)"
    fi
}

main() {
    bold "Repo Health Check"
    bold "================="

    check_skill_frontmatter
    check_workflow_crossrefs
    check_md_consistency
    check_fixture_verdicts
    check_bats
    check_shellcheck
    check_workflow_value_justification
    check_hook_permissions
    check_hook_wiring
    check_skill_fixture_coverage
    check_feature_integration
    check_doc_freshness
    check_persona_freshness
    check_md_semantic_divergence
    check_questions_doc

    echo
    if [[ $FAIL -eq 0 ]]; then
        green "All checks passed."
    else
        red "Some checks failed."
    fi
    exit "$FAIL"
}

# Run only when executed, so tests can source this file and call one check.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
