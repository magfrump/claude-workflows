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
# Checks:
#   1. Skill YAML frontmatter parses correctly (name + description present)
#   2. Workflow cross-references in CLAUDE.md/AGENTS.md/GEMINI.md resolve
#   3. CLAUDE.md/AGENTS.md/GEMINI.md reference the same workflows and skills
#   4. All test fixtures have corresponding expected-verdicts entries
#   5. BATS tests pass (when report outputs exist)
#   6. shellcheck passes on all .sh/.bash files
#   7. Workflow value-justification frontmatter is present
#   8. Hook scripts in hooks/ are executable
#   9. Skill test-fixture coverage report (soft warning, not a gate)
#  10. Feature integration: si-functions.sh orphan detection (soft warning)
#  11. Document freshness: flag stale spikes and onboarding docs (soft warning)
#  12. Persona critique freshness: flag persona-last-sampled >180 days (soft warning)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
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
    local drift_count=0
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
            drift_count=$((drift_count + 1))
            continue
        fi

        local file_ok=true

        # Check required fields: name, description, when
        if ! echo "$yaml" | grep -qE '^name:'; then
            fail "$basename: missing 'name' field"
            file_ok=false
        fi
        if ! echo "$yaml" | grep -qE '^description:'; then
            fail "$basename: missing 'description' field"
            file_ok=false
        fi
        if ! echo "$yaml" | grep -qE '^when:'; then
            fail "$basename: missing 'when' field"
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
        # Top-level keys are non-indented lines matching "key:" pattern.
        local allowed_keys="name description when requires lens persona-last-sampled"
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
        done)"
        if [[ -n "$unknown_keys" ]]; then
            fail "$basename: unknown top-level key(s): $unknown_keys"
            file_ok=false
        fi

        # Check requires entries have name and description sub-fields.
        if echo "$yaml" | grep -qE '^requires:'; then
            # Each requires entry should be a "- name: ..." followed by "  description: ..."
            # Detect bare string entries (lines starting with "  - " that are NOT "  - name:")
            local bare_entries
            bare_entries="$(echo "$yaml" | sed -n '/^requires:/,/^[a-z]/{/^requires:/d; /^[a-z]/d; p;}' \
                | grep -E '^[[:space:]]*-[[:space:]]' \
                | grep -vE '^[[:space:]]*-[[:space:]]+name:' || true)"
            if [[ -n "$bare_entries" ]]; then
                fail "$basename: 'requires' entries must be objects with 'name' and 'description' sub-fields"
                file_ok=false
            fi
        fi

        if $file_ok; then
            pass "$basename"
        else
            drift_count=$((drift_count + 1))
        fi
    done
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
            # Extract value-justification from frontmatter (between first --- and next ---)
            value="$(awk '
                NR==1 && /^---$/ { in_fm=1; next }
                in_fm && /^---$/ { exit }
                in_fm && /^value-justification:/ {
                    sub(/^value-justification:[[:space:]]*/, "")
                    gsub(/^["'"'"']|["'"'"']$/, "")
                    print
                }
            ' "$wf")"
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

# ── 9. Skill test-fixture coverage ────────────────────────────────────────

check_skill_fixture_coverage() {
    section "Skill test-fixture coverage"

    local total=0
    local covered=0
    local uncovered_skills=()

    for skill in "$REPO_ROOT"/skills/*.md; do
        [[ -f "$skill" ]] || continue
        total=$((total + 1))

        local skill_name
        skill_name="$(basename "$skill" .md)"

        local fixture_dir="$REPO_ROOT/test/skills/$skill_name/fixtures"
        if [[ -d "$fixture_dir" ]] && ls "$fixture_dir"/* &>/dev/null 2>&1; then
            covered=$((covered + 1))
            pass "$skill_name: has test fixtures"
        else
            uncovered_skills+=("$skill_name")
            warn "$skill_name: no test fixtures found"
        fi
    done

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

    # Collect all .sh entry-point scripts (everything except si-functions.sh itself)
    local entry_scripts=()
    while IFS= read -r -d '' f; do
        [[ "$f" == "$lib_file" ]] && continue
        entry_scripts+=("$f")
    done < <(find "$REPO_ROOT/scripts" -type f -name '*.sh' -not -path '*/.git/*' -print0)

    local orphan_count=0
    local total=${#functions[@]}
    local orphan_names=()

    for fname in "${functions[@]}"; do
        local found=false
        for script in "${entry_scripts[@]}"; do
            # Look for the function name being called (not just defined)
            # Match word boundary: the function name followed by space, quote, or $
            if grep -qE "(^|[^a-zA-Z_])${fname}([^a-zA-Z_0-9]|$)" "$script" 2>/dev/null; then
                found=true
                break
            fi
        done
        if $found; then
            pass "$fname: called from entry point"
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

# ── 11. Document freshness (spikes + onboarding docs) ────────────────────

check_doc_freshness() {
    section "Document freshness (spikes + onboarding)"

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

    if [[ ${#docs[@]} -eq 0 ]]; then
        pass "No spike or onboarding docs found — nothing to check"
        return
    fi

    for doc in "${docs[@]}"; do
        local relpath="${doc#"$REPO_ROOT"/}"

        # Extract Last verified date — match bold inline field outside code blocks.
        # Skip lines inside fenced code blocks (``` ... ```).
        local last_verified
        last_verified="$(awk '
            /^```/ { in_code = !in_code; next }
            !in_code && /^\*\*Last verified:\*\*/ {
                sub(/^\*\*Last verified:\*\*[[:space:]]*/, "")
                print
                exit
            }
        ' "$doc")"

        # Extract Relevant paths — same approach, handle multi-word comma/space-separated
        local relevant_paths
        relevant_paths="$(awk '
            /^```/ { in_code = !in_code; next }
            !in_code && /^\*\*Relevant paths:\*\*/ {
                sub(/^\*\*Relevant paths:\*\*[[:space:]]*/, "")
                print
                exit
            }
        ' "$doc")"

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

# ── 12. Persona critique freshness ────────────────────────────────────────

# Soft-warning check: skills that carry a `persona-last-sampled: YYYY-MM-DD`
# frontmatter field are flagged when the date is older than ~6 months
# (180 days). Skills without the field are silently skipped — the field
# is opt-in for persona-style critique skills. Re-sampling is a separate
# manual step; this check only surfaces what needs attention.
check_persona_freshness() {
    section "Persona critique freshness"

    local stale_days=180
    local now_epoch
    now_epoch="$(date +%s)"

    local checked=0
    local fresh=0
    local stale=0
    local malformed=0

    for skill in "$REPO_ROOT"/skills/*.md; do
        [[ -f "$skill" ]] || continue
        local basename
        basename="$(basename "$skill")"

        # Extract YAML frontmatter (same convention as check #1).
        local yaml
        yaml="$(sed -n '/^---$/,/^---$/p' "$skill" | sed '1d;$d')"
        [[ -n "$yaml" ]] || continue

        # Extract the persona-last-sampled value (top-level key).
        # awk (not grep) so a missing field doesn't trip set -e + pipefail.
        local sampled
        sampled="$(echo "$yaml" | awk '
            /^persona-last-sampled:/ {
                sub(/^persona-last-sampled:[[:space:]]*/, "")
                print
                exit
            }
        ')"

        # Field is opt-in — silently skip skills without it.
        [[ -n "$sampled" ]] || continue

        checked=$((checked + 1))

        # Validate YYYY-MM-DD format (mirrors check #11).
        if ! [[ "$sampled" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            warn "$basename: 'persona-last-sampled' is not a valid date: $sampled"
            malformed=$((malformed + 1))
            continue
        fi

        # GNU `date -d` — repo is Linux per other prior art (git log --since).
        local sampled_epoch
        sampled_epoch="$(date -d "$sampled" +%s 2>/dev/null || echo "")"
        if [[ -z "$sampled_epoch" ]]; then
            warn "$basename: could not parse persona-last-sampled date: $sampled"
            malformed=$((malformed + 1))
            continue
        fi

        local age_days=$(( (now_epoch - sampled_epoch) / 86400 ))
        if (( age_days > stale_days )); then
            warn "$basename: STALE — persona last sampled $age_days days ago ($sampled); re-sample recommended"
            stale=$((stale + 1))
        else
            pass "$basename: fresh ($age_days days since $sampled)"
            fresh=$((fresh + 1))
        fi
    done

    echo
    bold "  Persona freshness: $checked checked, $fresh fresh, $stale stale, $malformed malformed"
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
    check_workflow_value_justification
    check_hook_permissions
    check_skill_fixture_coverage
    check_feature_integration
    check_doc_freshness
    check_persona_freshness

    echo
    if [[ $FAIL -eq 0 ]]; then
        green "All checks passed."
    else
        red "Some checks failed."
    fi
    exit "$FAIL"
}

main "$@"
