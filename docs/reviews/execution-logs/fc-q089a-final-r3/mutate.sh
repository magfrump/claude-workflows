#!/usr/bin/env bash
# Mutation probes for code-fact-check q089a final r3. Each probe copies a fresh
# git archive of afe1ae59 into its own mktemp dir, applies one mutation, and runs
# the named bats test(s). Hermetic: HOME, TMPDIR, CLAUDE_DEVC_CONFIG_DIR,
# CC_PUSH_CLONES_DIR all point inside the probe dir.
set -u
BASE=/home/node/.claude/jobs/00bcf178/tmp
REPO=/workspace/.claude/wt-q089
export LC_ALL=C

probe() { # name, filter, mutation-command (run inside dir)
  local name="$1" filter="$2" mut="$3" d
  d="$(mktemp -d "$BASE/fcr3-mut-$name.XXXXXX")" || exit 1
  cd "$d" || exit 1
  git -C "$REPO" archive afe1ae59 | tar -x -C "$d" || exit 1
  mkdir -p .p/home .p/tmp .p/cfg .p/clones
  echo "=== probe $name ($(date -u +%FT%TZ)) dir=$d"
  echo "mutation: $mut"
  bash -c "$mut" || { echo "mutation failed"; return; }
  git -C "$REPO" diff --no-index --stat -- /dev/null /dev/null >/dev/null 2>&1
  env HOME="$d/.p/home" TMPDIR="$d/.p/tmp" CLAUDE_DEVC_CONFIG_DIR="$d/.p/cfg" \
      CC_PUSH_CLONES_DIR="$d/.p/clones" timeout 600 bats -f "$filter" "test/$4" 2>&1
  echo "bats exit=$?"
  cd "$BASE" || exit 1
}

# P1: --list would report cc-push as changed on a scan-only change. Does the
# test's `!= *"cc-push refuses"*` catch it?
probe p1 'reports host-tool state' \
  "sed -i 's|perr=\"\$(verify_host_tools \"\$cfg_real\" cc-push.sh cc-gitdir.sh)\"|perr=\"\$(verify_host_tools \"\$cfg_real\" cc-push.sh cc-gitdir.sh cc-exit-scan.sh)\"|' devcontainer-config/cc-isolated.sh && grep -n 'perr=\"' devcontainer-config/cc-isolated.sh" \
  cc-isolated-functions.bats

# P2: bare readlink assignment in --list.
probe p2 'parent is missing' \
  "sed -i 's#cfg_real=\"\$(readlink -f -- \"\$(config_dir)\")\" || cfg_real=\"\$(config_dir)\"#cfg_real=\"\$(readlink -f -- \"\$(config_dir)\")\"#' devcontainer-config/cc-isolated.sh && grep -n 'cfg_real=\"' devcontainer-config/cc-isolated.sh" \
  cc-isolated-functions.bats

# P3: bless writes the boundary manifest in place before computing host tools.
probe p3 'a failure changes neither manifest' \
  "sed -i 's#if ! compute_manifest > \"\$new_m\" || ! compute_host_tools_manifest > \"\$new_h\"; then#if ! compute_manifest > \"\$(manifest_path)\" || ! compute_host_tools_manifest > \"\$new_h\"; then#' devcontainer-config/cc-isolated.sh && grep -n 'if ! compute_manifest' devcontainer-config/cc-isolated.sh" \
  cc-isolated-functions.bats

# P4: cc-push with its self-check removed (the if-block becomes a no-op).
probe p4 'checks itself and cc-gitdir.sh' \
  "sed -i 's#^if ! host_tools_err=\"\$(verify_host_tools \"\$CC_PUSH_DIR\" cc-push.sh cc-gitdir.sh)\"; then#if false; then#' devcontainer-config/cc-push.sh && grep -n '^if false; then' devcontainer-config/cc-push.sh" \
  cc-push.bats
