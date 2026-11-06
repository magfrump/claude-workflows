#!/usr/bin/env bats
# @category fast
# Accidental-drift guard (Q-147, from Q-089 unit A's finding A6): a new helper that
# an entry point plainly sources, directly or through a file it sources, must be in
# that entry point's verify_host_tools list, or it runs unchecked. No other test ties
# the list to the `source` lines; the two names in use today are pinned one by one.
#
# A grep guards plain spellings only, and it cannot be complete for bash: Q-089's
# fourth review pass showed that. Forms this one misses include `FOO=1 . f`,
# `FOO=1 source f`, one-line case arms, a quoted or obfuscated `source`, and `$c f`.
# It also does not see a tool run by name, cc-verify.sh (no verify_host_tools call;
# it sources nothing today), the lists `--list` passes, or whether the check comes
# before the source or gates it. An end-of-line comment or string quoting a check
# call above the real one is read as the list. It is hardening against a refactor,
# and the runtime checks do not depend on it.
#
# The spelling rule is cc-verify.sh's own source_lines_ok, read from that file
# rather than restated here, so there is one grammar to keep.
bats_require_minimum_version 1.5.0

setup() {
  SRC="$BATS_TEST_DIRNAME/../devcontainer-config"
  T="$(mktemp -d)"
  sed -n '/^source_lines_ok() {/,/^}/p' "$SRC/cc-verify.sh" > "$T/source-lines-ok.sh"
  [ -s "$T/source-lines-ok.sh" ] || { echo "no source_lines_ok in cc-verify.sh"; return 1; }
  # shellcheck source=/dev/null
  source "$T/source-lines-ok.sh"
  mkdir "$T/cfg"
  cp "$SRC"/cc-*.sh "$T/cfg/"
}

teardown() {
  rm -rf "$T"
}

# check_entry DIR ENTRY: what ENTRY plainly sources, directly or through what those
# files source, is in its first verify_host_tools call and in host_tool_files. Prints
# the first problem. It works on copies, which it adjusts for the shared grammar:
# CC_PUSH_DIR, which the grammar does not know, becomes the launcher's variable (so a
# refused line shows that name), and each copy gets a final newline, because the
# grammar's read loop never sees an unterminated last line.
check_entry() {
  local dir="$1" entry="$2" args hosts why f SOURCED=()
  args="$(grep -vE '^[[:space:]]*#' "$dir/$entry" \
    | grep -oE 'verify_host_tools "\$CC_(ISOLATED|PUSH)_DIR"( [a-z-]+\.sh)+' | head -1 | cut -d' ' -f3-)" || true
  [ -n "$args" ] || { echo "no verify_host_tools call in $entry"; return 1; }
  for f in "$dir"/cc-*.sh; do
    sed -i 's/CC_PUSH_DIR/CC_ISOLATED_DIR/g' "$f"
    echo >> "$f"
  done
  why="$(source_lines_ok "$dir" "$entry")" || { echo "not a plain source line: $why"; return 1; }
  source_lines_ok "$dir" "$entry"
  # Positive control: both entry points reach cc-gitdir.sh (the launcher through the scan).
  [[ " ${SOURCED[*]} " == *" cc-gitdir.sh "* ]] || { echo "parse missed cc-gitdir.sh for $entry: ${SOURCED[*]}"; return 1; }
  hosts="$(bash -c 'source "$1"; host_tool_files' _ "$dir/cc-isolated.sh")"
  for f in "${SOURCED[@]}"; do
    [[ " $args " == *" $f "* ]] || { echo "$entry sources $f unchecked"; return 1; }
    grep -qx -- "$f" <<< "$hosts" || { echo "$f is not a host tool"; return 1; }
  done
}

@test "plain source lines in the entry points stay inside their verify_host_tools lists" {
  run check_entry "$T/cfg" cc-isolated.sh
  [ "$status" -eq 0 ] || { echo "$output"; return 1; }
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "a plain source of a host tool outside the entry point's list is named" {
  echo 'source "$CC_PUSH_DIR/cc-exit-scan.sh"' >> "$T/cfg/cc-push.sh"
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"cc-push.sh sources cc-exit-scan.sh unchecked"* ]]
}

@test "a plain source on a last line with no newline is still read" {
  printf 'source "$CC_PUSH_DIR/cc-exit-scan.sh"' >> "$T/cfg/cc-push.sh"
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"cc-push.sh sources cc-exit-scan.sh unchecked"* ]]
}

@test "a helper that names its directory CC_PUSH_DIR is read like cc-push.sh itself" {
  echo 'source "$CC_PUSH_DIR/cc-gitdir.sh"' > "$T/cfg/cc-helper.sh"
  echo 'source "$CC_PUSH_DIR/cc-helper.sh"' >> "$T/cfg/cc-push.sh"
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"cc-push.sh sources cc-helper.sh unchecked"* ]]
}

@test "a name dropped from the launcher's list is named, through the file that sources it" {
  sed -i 's/\(verify_host_tools "\$CC_ISOLATED_DIR" cc-exit-scan\.sh\) cc-gitdir\.sh/\1/' "$T/cfg/cc-isolated.sh"
  run check_entry "$T/cfg" cc-isolated.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"cc-isolated.sh sources cc-gitdir.sh unchecked"* ]]
}

@test "a new helper in the check list but not in host_tool_files is named" {
  : > "$T/cfg/cc-helper.sh"
  echo 'source "$CC_PUSH_DIR/cc-helper.sh"' >> "$T/cfg/cc-push.sh"
  sed -i 's/\(verify_host_tools "\$CC_PUSH_DIR" cc-push\.sh\)/\1 cc-helper.sh/' "$T/cfg/cc-push.sh"
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"cc-helper.sh is not a host tool"* ]]
}

@test "a dot source, or a source from any other directory, is refused as not plain" {
  local good="$T/cc-push.good"
  cp "$T/cfg/cc-push.sh" "$good"
  echo '. "$CC_PUSH_DIR/cc-gitdir.sh"' >> "$T/cfg/cc-push.sh"
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *'not a plain source line'*'. "$CC_ISOLATED_DIR/cc-gitdir.sh"'* ]]
  cp "$good" "$T/cfg/cc-push.sh"
  echo 'source "$(config_dir)/cc-gitdir.sh"' >> "$T/cfg/cc-push.sh"
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *'not a plain source line'*'$(config_dir)/cc-gitdir.sh'* ]]
}

@test "an entry point with no check call, or that no longer reaches cc-gitdir.sh, fails rather than passes empty" {
  local good="$T/cc-push.good"
  cp "$T/cfg/cc-push.sh" "$good"
  sed -i '/^if ! host_tools_err=/s/verify_host_tools/verify_tools/' "$T/cfg/cc-push.sh"
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"no verify_host_tools call in cc-push.sh"* ]]
  cp "$good" "$T/cfg/cc-push.sh"
  sed -i '/^source "\$CC_PUSH_DIR\/cc-gitdir\.sh"$/d' "$T/cfg/cc-push.sh"
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"parse missed cc-gitdir.sh for cc-push.sh"* ]]
}

@test "a missing sourced file fails, naming it" {
  rm "$T/cfg/cc-gitdir.sh"
  run check_entry "$T/cfg" cc-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"cc-gitdir.sh is missing"* ]]
}
