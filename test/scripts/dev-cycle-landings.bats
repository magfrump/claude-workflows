#!/usr/bin/env bats
# @category fast
# Section 6b of scripts/dev-cycle.sh (scripts/lib/landings.sh): code landings
# on main that came outside the build loop. Each test builds a throwaway repo
# under $BATS_TEST_TMPDIR; this repo is untouched. No network tool is run.

bats_require_minimum_version 1.5.0

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    DC="$REPO_ROOT/scripts/dev-cycle.sh"
    # shellcheck disable=SC2046  # one name per line
    unset $(git rev-parse --local-env-vars)
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
    export HOME="$BATS_TEST_TMPDIR/home"; unset CLAUDE_CONFIG_DIR
    mkdir -p "$HOME"
    R="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$R" && cd "$R" || return 1
    git init -q -b main
    git commit -q --allow-empty -m initial
}

# commit MSG PATH=CONTENT...: one commit on the current branch.
commit() {
    local m="$1" kv; shift
    for kv in "$@"; do mkdir -p "$(dirname "${kv%%=*}")"; printf '%s\n' "${kv#*=}" > "${kv%%=*}"; git add -- "${kv%%=*}"; done
    git commit -q -m "$m"
}
section() { sed -n '/^## 6b\./,/^## 7\./p' <<< "$output"; }
AMBER=$'# Rubric\n\n## 🟡 Must Address\n\n| ID | Finding | Status | Author note |\n|---|---|---|---|\n| A1 | a gap | Open | |'

@test "a hand commit to skills/ with no rubric is listed with none" {
    commit "feat: x" skills/x/SKILL.md=one
    run --separate-stderr bash "$DC" --since=2000-01-01
    [ "$status" -eq 0 ]
    s="$(section)"
    [[ "$s" == *"1 code landing(s) outside the build loop; 0 commit(s) not read"* ]] || { echo "$s"; return 1; }
    [[ "$s" == *"· feat: x"* && "$s" == *"code paths (1): skills/x/SKILL.md"* ]] || { echo "$s"; return 1; }
    [[ "$s" == *"rubric none: "*"adds or changes no code-review rubric"* ]] || { echo "$s"; return 1; }
}

@test "a hand merge carrying a rubric with an open row lists that row" {
    git checkout -q -b f
    commit "fix: y" scripts/y.sh=y "docs/reviews/code-review-rubric-2026-01-01-f.md=$AMBER"
    git checkout -q main
    git merge -q --no-ff f -m "Merge branch 'f'"
    run --separate-stderr bash "$DC" --since=2000-01-01
    s="$(section)"
    [[ "$s" == *"· Merge branch 'f'"* && "$s" == *"code paths (1): scripts/y.sh"* ]] || { echo "$s"; return 1; }
    [[ "$s" == *"rubric open docs/reviews/code-review-rubric-2026-01-01-f.md A1 amber: Open"* ]] || { echo "$s"; return 1; }
    [[ "$s" != *"rubric none"* ]] || { echo "$s"; return 1; }
}

@test "a docs(...) commit that changes a skill is listed: paths decide, not the prefix" {
    commit "docs(reader): notes" skills/r/SKILL.md=r docs/notes.md=n
    run --separate-stderr bash "$DC" --since=2000-01-01
    s="$(section)"
    [[ "$s" == *"· docs(reader): notes"* && "$s" == *"code paths (1): skills/r/SKILL.md"* ]] || { echo "$s"; return 1; }
}

@test "a build-loop merge and a docs-only commit are not listed" {
    git checkout -q -b b
    commit "feat: z" hooks/z.sh=z workflows/w.md=w
    git checkout -q main
    git merge -q --no-ff b -m "Merge branch 'b' (build-loop self-merge)" -m "Build-loop-gate: 2026-01-01-b"
    commit "docs: only" docs/a.md=a README.md=r
    run --separate-stderr bash "$DC" --since=2000-01-01
    [ "$status" -eq 0 ]
    s="$(section)"
    [[ "$s" == *"None in the window."* ]] || { echo "$s"; return 1; }
}

@test "a merge with the trailer anywhere but line 3 after a blank line is still listed" {
    git checkout -q -b b
    commit "feat: z" hooks/z.sh=z
    git checkout -q main
    git merge -q --no-ff b -m "Merge b, not Build-loop-gate: x"
    commit "feat: z2" hooks/z.sh=z2 && git checkout -q b && commit "feat: y" hooks/y.sh=y && git checkout -q main
    git merge -q --no-ff b -m "Build-loop-gate: x hand merge"
    git checkout -q b && commit "feat: w" hooks/w.sh=w && git checkout -q main
    git merge -q --no-ff b -m "Merge b by hand" -m "Quoting an old one:" -m "Build-loop-gate: 2026-01-01-old"
    run --separate-stderr bash "$DC" --since=2000-01-01
    s="$(section)"
    [[ "$s" == *"4 code landing(s)"* ]] || { echo "$s"; return 1; }
    [[ "$s" == *"· Merge b, not Build-loop-gate: x"* && "$s" == *"· Build-loop-gate: x hand merge"* && "$s" == *"· Merge b by hand"* ]] || { echo "$s"; return 1; }
}

@test "a repo-local log output encoding changes nothing in the section" {
    git checkout -q -b f
    commit "fix: y" scripts/y.sh=y "docs/reviews/code-review-rubric-2026-01-01-f.md=$AMBER"
    commit "fix: after the rubric" scripts/y.sh=y2
    git checkout -q main
    git merge -q --no-ff f -m "Merge branch 'f'"
    run --separate-stderr bash "$DC" --since=2000-01-01
    want="$(section)"
    [[ "$want" == *"rubric stale docs/reviews/code-review-rubric-2026-01-01-f.md: 1 fix(...) commits"* ]] || { echo "$want"; return 1; }
    git config i18n.logOutputEncoding UTF-16
    run --separate-stderr bash "$DC" --since=2000-01-01
    [ "$(section)" == "$want" ] || { diff <(echo "$want") <(section); return 1; }
}

@test "fp_blob and showpath are the same as build-loop.sh's" {
    body() { awk -v f="$1" 'index($0, f "() {") == 1 { on = 1 } on { print } on && /^}|^[a-z_]+\(\) \{.*\}$/ { exit }' "$2"; }
    for f in fp_blob showpath; do
        a="$(body "$f" "$REPO_ROOT/scripts/build-loop.sh")"; b="$(body "$f" "$REPO_ROOT/scripts/lib/landings.sh")"
        [ -n "$a" ] && [ "$a" == "$b" ] || { echo "$f differs"; diff <(echo "$a") <(echo "$b"); return 1; }
    done
}

@test "an unreadable rubric is named, not counted as none" {
    mkdir -p docs/reviews
    ln -s ../../elsewhere.md docs/reviews/code-review-rubric-2026-01-01-s.md
    git add docs/reviews
    commit "feat: s" skills/s/SKILL.md=s "docs/reviews/code-review-rubric-2026-01-02-t.md=# no tables here"
    run --separate-stderr bash "$DC" --since=2000-01-01
    s="$(section)"
    [[ "$s" == *"rubric unread docs/reviews/code-review-rubric-2026-01-01-s.md: not a regular file"* ]] || { echo "$s"; return 1; }
    [[ "$s" == *"rubric unread docs/reviews/code-review-rubric-2026-01-02-t.md: no red or amber table"* ]] || { echo "$s"; return 1; }
    [[ "$s" != *"rubric none"* && "$s" != *"rubric clean"* ]] || { echo "$s"; return 1; }
}

@test "a commit whose changes cannot be read is named on a Not read line" {
    commit "feat: gone" skills/g/SKILL.md=g
    # Remove the commit's tree: log still lists the commit, diff-tree fails.
    t="$(git rev-parse "HEAD^{tree}")"
    rm -f ".git/objects/${t:0:2}/${t:2}"
    run --separate-stderr bash "$DC" --since=2000-01-01
    s="$(section)"
    [[ "$s" == *"0 code landing(s) outside the build loop; 1 commit(s) not read"* ]] || { echo "$s"; return 1; }
    [[ "$s" == *"- Not read: "*"its changed paths could not be listed"* && "$s" != *"None in the window."* ]] || { echo "$s"; return 1; }
}

@test "commits before the window are not listed" {
    GIT_COMMITTER_DATE="2001-01-01T00:00:00Z" commit "feat: old" skills/o/SKILL.md=o
    run --separate-stderr bash "$DC" --since=2010-01-01
    s="$(section)"
    [[ "$s" == *"None in the window."* ]] || { echo "$s"; return 1; }
}

@test "a missing landings lib says the section was NOT checked" {
    d="$BATS_TEST_TMPDIR/copy"; mkdir -p "$d/lib"
    cp "$DC" "$d/"; cp "$REPO_ROOT/scripts/lib/dev-cycle-read.sh" "$REPO_ROOT/scripts/lib/rubric-check.sh" "$d/lib/"
    commit "feat: x" skills/x/SKILL.md=one
    run --separate-stderr bash "$d/dev-cycle.sh" --since=2000-01-01
    [ "$status" -eq 0 ]
    s="$(section)"
    [[ "$s" == *"**Out-of-loop landings were NOT checked** — lib/landings.sh is missing beside this script."* ]] || { echo "$s"; return 1; }
    [[ "$output" == *"## 8. Skipped inputs"* ]]
}

@test "a root commit that adds code is compared with the empty tree and listed" {
    rm -rf .git && git init -q -b main
    commit "feat: root" scripts/r.sh=r
    run --separate-stderr bash "$DC" --since=2000-01-01
    s="$(section)"
    [[ "$s" == *"1 code landing(s) outside the build loop; 0 commit(s) not read"* && "$s" == *"code paths (1): scripts/r.sh"* ]] || { echo "$s"; return 1; }
}
