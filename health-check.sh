#!/usr/bin/env bash
# Self-discovering repo health check.
# Validates repo integrity by globbing for skills, workflows, fixtures, and
# shell scripts rather than hardcoding file lists.
#
# Checks:
#   1. Skill YAML frontmatter parses correctly (name + description present)
#   2. Workflow cross-references in CLAUDE.md/AGENTS.md/GEMINI.md resolve
#   3. CLAUDE.md/AGENTS.md/GEMINI.md reference the same workflows and skills
#   4. All test fixtures have corresponding expected-verdicts entries
#   5. BATS tests pass (when report outputs exist)
#   6. shellcheck passes on all .sh/.bash files
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
FAIL=0

# --- Color helpers ---
red()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

pass() { green "  ✓ $*"; }
fail() { red   "  ✗ $*"; FAIL=1; }
warn() { yellow "  ⚠ $*"; }
section() { echo; bold "── $* ──"; }

# ── 1. Skill YAML frontmatter ──────────────────────────────────────────────

check_skill_frontmatter() {
    section "Skill YAML frontmatter"
    local count=0
    for skill in "$REPO_ROOT"/skills/*.md; do
        [[ -f "$skill" ]] || continue
        count=$((count + 1))
        local basename
        basename="$(basename "$skill")"

        # Extract YAML block between first two --- lines
        local yaml
        yaml="$(sed -n '/^---$/,/^---$/p' "$skill" | sed '1d;$d')"

        if [[ -z "$yaml" ]]; then
            fail "$basename: no YAML frontmatter found"
            continue
        fi

        # Check required fields
        if ! echo "$yaml" | grep -qE '^name:'; then
            fail "$basename: missing 'name' field"
        elif ! echo "$yaml" | grep -qE '^description:'; then
            fail "$basename: missing 'description' field"
        else
            pass "$basename"
        fi
    done
    if [[ $count -eq 0 ]]; then
        fail "No skill files found in skills/"
    else
        pass "$count skill(s) checked"
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
    grep -oE '\*\*(@\./workflows/)?[a-z][-a-z0-9]*\.md\*\*' "$file" \
        | sed 's/\*\*//g; s|@\./workflows/||' \
        | sort -u
}

check_workflow_crossrefs() {
    section "Workflow cross-references"
    for mdfile in CLAUDE.md AGENTS.md GEMINI.md; do
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

    for mdfile in CLAUDE.md AGENTS.md GEMINI.md; do
        local path="$REPO_ROOT/$mdfile"
        [[ -f "$path" ]] || continue
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
        for fixture in "$skill_dir"/fixtures/*; do
            [[ -f "$fixture" ]] || continue
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
            if [[ ! -f "$skill_dir/fixtures/$key" ]]; then
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

check_bats() {
    section "BATS tests"

    if ! command -v bats &>/dev/null; then
        warn "bats not installed, skipping"
        return
    fi

    local bats_files=()
    for f in "$REPO_ROOT"/test/skills/*.bats "$REPO_ROOT"/test/hooks/*.bats; do
        [[ -f "$f" ]] && bats_files+=("$f")
    done

    if [[ ${#bats_files[@]} -eq 0 ]]; then
        warn "No .bats files found"
        return
    fi

    # Eval bats require generated report outputs; check if any exist
    local has_reports=false
    for output_dir in "$REPO_ROOT"/test/skills/*/output/; do
        if [[ -d "$output_dir" ]] && ls "$output_dir"/*.md &>/dev/null 2>&1; then
            has_reports=true
            break
        fi
    done

    if ! $has_reports; then
        warn "No report outputs found — skipping eval/format BATS (run generate-reports.bash first)"
        # Still run non-eval bats if any exist
        local non_eval=()
        for f in "${bats_files[@]}"; do
            case "$(basename "$f")" in
                *-eval.bats|*-format.bats) ;;
                *) non_eval+=("$f") ;;
            esac
        done
        if [[ ${#non_eval[@]} -gt 0 ]]; then
            if bats "${non_eval[@]}"; then
                pass "Non-eval BATS tests passed"
            else
                fail "BATS tests failed"
            fi
        fi
        return
    fi

    if bats "${bats_files[@]}"; then
        pass "All BATS tests passed (${#bats_files[@]} file(s))"
    else
        fail "BATS tests failed"
    fi
}

# ── 6. shellcheck ───────────────────────────────────────────────────────────

check_shellcheck() {
    section "shellcheck"

    if ! command -v shellcheck &>/dev/null; then
        warn "shellcheck not installed, skipping"
        return
    fi

    local shell_files=()
    while IFS= read -r -d '' f; do
        shell_files+=("$f")
    done < <(find "$REPO_ROOT" -type f \( -name '*.sh' -o -name '*.bash' \) -not -path '*/.git/*' -print0)

    # Also include .bats files — they're bash
    while IFS= read -r -d '' f; do
        shell_files+=("$f")
    done < <(find "$REPO_ROOT" -type f -name '*.bats' -not -path '*/.git/*' -print0)

    if [[ ${#shell_files[@]} -eq 0 ]]; then
        warn "No shell files found"
        return
    fi

    local all_ok=true
    for f in "${shell_files[@]}"; do
        local relpath="${f#"$REPO_ROOT"/}"
        # Use -x to follow sourced files; -e SC1091 to skip missing sourced files
        # Use -s bash for .bats files that lack a shebang
        if shellcheck -x -e SC1091 -s bash "$f" 2>/dev/null; then
            pass "$relpath"
        else
            fail "$relpath"
            all_ok=false
        fi
    done
}

# ── Run all checks ─────────────────────────────────────────────────────────

main() {
    bold "Repo Health Check"
    bold "================="

    check_skill_frontmatter
    check_workflow_crossrefs
    check_md_consistency
    check_fixture_verdicts
    check_bats
    check_shellcheck

    echo
    if [[ $FAIL -eq 0 ]]; then
        green "All checks passed."
    else
        red "Some checks failed."
    fi
    exit "$FAIL"
}

main "$@"
