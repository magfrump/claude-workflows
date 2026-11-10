#!/usr/bin/env bats
# @category slow
# scripts/confine-tests.sh: the probe verdict, the refusal to run tests
# unconfined, usage errors, primitive selection, and that each word of the test
# command reaches the child as its own argv element.
#
# WHAT THESE TESTS DO NOT SHOW. Every test but one runs the script on a PATH
# built here: the real bash, sh, cat and awk, plus stand-ins for bwrap, unshare
# and ip. A stand-in creates no namespace, so nothing here shows that the
# network is denied, that the real bwrap accepts the profile the script hands
# it, or that `lo` comes up. These tests pin what the script asks its primitive
# for and what it does with the answer; only a live confined run shows that
# confinement works (docs/working/research-2026-11-10-confine-tests-bats.md).
#
# A stand-in is at least as strict as its tool (decision log row 44): it takes
# the exact argv shapes the script uses today, under a mode the test names, and
# any other call fails the test that made it (see confine()).

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/confine-tests.sh"
NO_PRIMITIVE='confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.'
NO_IP='confine-tests: `ip` (iproute2) not found — cannot bring loopback up.'
NO_LO_OVER_BWRAP='confine-tests: --no-loopback is not supported by the bwrap primitive.'
LO_WARNING='confine-tests: WARNING — --no-loopback forces the unshare primitive.'
# Words a shell would mangle if any step re-parsed them: a space, leading
# dashes (the script's own flags among them), an empty word, substitutions, a
# separator, a glob, a quote and a newline.
TRICKY=('two words' -n --probe --no-loopback -- '' '$(touch pwned)' '`touch pwned`'
        '; touch pwned' '*' "it's" $'line one\nline two')

# A call is recorded as one file, $STUB_LOG/NAME.N for NAME's Nth call, holding
# the argv with a NUL after each element: an empty file is a call with no
# arguments, and an argument may hold a newline.
RECORD_CALL='n=1; while [[ -e "$STUB_LOG/$name.$n" ]]; do n=$((n + 1)); done
if [[ $# -gt 0 ]]; then printf "%s\0" "$@"; fi > "$STUB_LOG/$name.$n"'

setup() {
  T="$BATS_TEST_TMPDIR" LOG="$BATS_TEST_TMPDIR/log" TOOLS="$BATS_TEST_TMPDIR/tools"
  RECORD="$T/my cmds/record argv"
  mkdir -p "$LOG" "$TOOLS" "$T/my cmds" "$T/work dir" "$T"/stub/{bwrap,unshare,ip}
  # The script runs in a directory whose name holds a space, spelled the way a
  # fresh bash spells it ($PWD does not pass through `env -i`).
  WORK="$(cd "$T/work dir" && pwd -P)"
  # The real tools the script and the stand-ins need, and no others: the real
  # unshare sits in the same directory as bash, so the ambient PATH is no use.
  local tool
  for tool in bash sh cat awk; do
    ln -s "$(type -P "$tool")" "$TOOLS/$tool"
  done
  # The test command: it records its argv as "child" and exits $CHILD_EXIT.
  # One copy has a space in its path; one is on PATH under a name starting "-".
  printf '%s\n' '#!/usr/bin/env bash' 'name=child' "$RECORD_CALL" 'exit "${CHILD_EXIT:-0}"' > "$RECORD"
  cp "$RECORD" "$TOOLS/-record"
  write_stub
  for tool in bwrap unshare ip; do cp "$T/stub/stub" "$T/stub/$tool/$tool"; done
  chmod +x "$RECORD" "$TOOLS/-record" "$T"/stub/*/*
  # The profile the script hands bwrap for a run; the test command follows it.
  PROFILE=(--ro-bind / / --dev /dev --proc /proc --tmpfs /tmp --setenv TMPDIR /tmp
           --bind "$WORK" "$WORK" --unshare-net --unshare-pid --die-with-parent
           --chdir "$WORK" --)
  cd "$WORK" || return 1
}

teardown() {
  # bats shows only the failing line; add what the script and stand-ins did.
  [[ -n "${BATS_TEST_COMPLETED:-}" ]] && return 0
  printf 'status: %s\nstdout:\n%s\nstderr:\n%s\ncalls:\n' "${status:-}" "${output:-}" "${stderr:-}"
  local f
  for f in "$LOG"/*.*; do
    [[ -e "$f" ]] || continue
    printf '  %s:' "${f##*/}"
    if [[ -s "$f" ]]; then xargs -0 printf ' %q' < "$f"; fi
    echo
  done
  if [[ -e "$LOG/unexpected" ]]; then cat "$LOG/unexpected"; fi
}

# The stand-in for bwrap, unshare and ip (one file, installed under each name).
# It records its call, then accepts only these calls, by mode (STUB_BWRAP,
# STUB_UNSHARE, STUB_IP):
#   bwrap    the probe: ok and run-fails succeed, refused fails;
#            the run profile then a command: ok execs it, run-fails fails
#   unshare  the probe (`-rn true`): ok succeeds, refused fails;
#            `-rn -- COMMAND...`: ok execs it
#   ip       `link set lo up`: ok succeeds, fails fails
# Any other argv, and any call with the mode unset, is written to
# $STUB_LOG/unexpected and exits 99. A run execs the command unconfined: that
# is the part a stand-in cannot replace.
write_stub() {
  { printf '%s\n' '#!/usr/bin/env bash' 'set -u' 'name="${0##*/}"' "$RECORD_CALL"; cat <<'EOF'; } > "$T/stub/stub"
q() { printf '%d:' "$#"; if [[ $# -gt 0 ]]; then printf ' %q' "$@"; fi; }
argv=("$@")
is() { [[ "$(q "${argv[@]}")" == "$(q "$@")" ]]; }  # this call's argv is exactly "$@"
var="STUB_${name^^}"
mode="${!var:-unset}"
case "$name" in
  bwrap)
    profile=(--ro-bind / / --dev /dev --proc /proc --tmpfs /tmp --setenv TMPDIR /tmp
             --bind "$PWD" "$PWD" --unshare-net --unshare-pid --die-with-parent
             --chdir "$PWD" --)
    if is --ro-bind / / --unshare-net -- true; then
      case "$mode" in ok|run-fails) exit 0 ;; refused) exit 1 ;; esac
    elif [[ $# -gt ${#profile[@]} ]] && is "${profile[@]}" "${@:${#profile[@]}+1}"; then
      case "$mode" in
        ok) shift "${#profile[@]}"; exec -- "$@" ;;
        run-fails) echo "stub bwrap: run refused" >&2; exit 1 ;;
      esac
    fi
    ;;
  unshare)
    if is -rn true; then
      case "$mode" in ok) exit 0 ;; refused) exit 1 ;; esac
    elif [[ $# -ge 3 && "$mode" == ok ]] && is -rn -- "${@:3}"; then
      shift 2; exec -- "$@"
    fi
    ;;
  ip)
    if is link set lo up; then
      case "$mode" in ok) exit 0 ;; fails) echo "stub ip: cannot raise lo" >&2; exit 1 ;; esac
    fi
    ;;
esac
printf 'stub %s: unexpected call under %s=%s: %s\n' "$name" "$var" "$mode" "$(q "$@")" >> "$STUB_LOG/unexpected"
exit 99
EOF
}

# confine "STUB..." [VAR=value...] -- [ARG...]: run the script with ARGs in an
# empty environment whose PATH holds the named stand-ins (of bwrap, unshare,
# ip) and the real tools. Fails the test when a stand-in refused a call.
confine() {
  local path="$TOOLS" tool assigns=()
  for tool in $1; do path="$T/stub/$tool:$path"; done
  shift
  while [[ $# -gt 0 && "$1" != -- ]]; do assigns+=("$1"); shift; done
  shift
  run --separate-stderr env -i PATH="$path" HOME="$T" TMPDIR="$T" STUB_LOG="$LOG" \
    "${assigns[@]}" "$SCRIPT" "$@"
  [[ ! -e "$LOG/unexpected" ]]
}

# calls NAME N [NAME N...]: each NAME (bwrap, unshare, ip or child) was called
# exactly N times.
calls() {
  local n
  while [[ $# -gt 0 ]]; do
    n=0
    while [[ -e "$LOG/$1.$((n + 1))" ]]; do n=$((n + 1)); done
    [[ "$n" -eq "$2" ]] || { echo "$1 was called $n time(s), want $2"; return 1; }
    shift 2
  done
}

# call NAME N [ARG...]: NAME's Nth call had exactly this argv.
call() {
  local file="$LOG/$1.$2"
  shift 2
  [[ -e "$file" ]] || { echo "no call ${file##*/}"; return 1; }
  if [[ $# -gt 0 ]]; then printf '%s\0' "$@"; fi | cmp -s - "$file" ||
    { echo "${file##*/}: want argv:$(printf ' %q' "$@")"; return 1; }
}

# refused STATUS FIRST_LINE: the script refused, saying so first, on stderr.
refused() {
  [ "$status" -eq "$1" ]
  [ "${stderr_lines[0]}" = "$2" ]
  [ -z "$output" ]
}

@test "with neither primitive installed, --probe exits 3 saying so first, and a test command is not run" {
  confine "" -- --probe
  refused 3 "$NO_PRIMITIVE"
  confine "" -- -- "$RECORD" "${TRICKY[@]}"
  refused 3 "$NO_PRIMITIVE"
  calls child 0
  [ ! -e pwned ]
}

@test "with both primitives installed and refused, the refusal names what went unenforced (H2)" {
  # This container's shape: unshare is installed and the kernel refuses it.
  confine "bwrap unshare ip" STUB_BWRAP=refused STUB_UNSHARE=refused -- --probe
  refused 3 "$NO_PRIMITIVE"
  call bwrap 1 --ro-bind / / --unshare-net -- true
  call unshare 1 -rn true
  confine "bwrap unshare ip" STUB_BWRAP=refused STUB_UNSHARE=refused -- -- "$RECORD" one
  refused 3 "$NO_PRIMITIVE"
  [[ "$stderr" == *"Your tests were NOT run."* ]]
  [[ "$stderr" == *"bwrap --unshare-net"* && "$stderr" == *"unshare -rn"* ]]
  # One probe of each per invocation: neither was asked to run the command.
  calls bwrap 2 unshare 2 child 0
}

@test "on this machine's own PATH, --probe gives one of its verdicts, and a refusal runs nothing" {
  # The one test without stand-ins: the script in its real position. It passes
  # whether or not this machine can confine, and shows no more than that the
  # verdict is well-formed and, on a refusal, that the command did not run.
  run --separate-stderr "$SCRIPT" --probe
  case "$status" in
    0) [[ "${lines[0]}" =~ ^confine-tests:\ primitive\ available:\ (bwrap|unshare)\ \(loopback=1\)$ ]] ;;
    3)
      [[ "${stderr_lines[0]}" == "$NO_PRIMITIVE" || "${stderr_lines[0]}" == "$NO_IP" ]]
      [ -z "$output" ]
      run --separate-stderr env STUB_LOG="$LOG" "$SCRIPT" -- "$RECORD" one
      [ "$status" -eq 3 ]
      calls child 0
      ;;
    *) false ;;
  esac
}

@test "an unknown flag, or a command given without --, is a usage error (exit 2) before any primitive is tried" {
  confine "bwrap unshare ip" STUB_BWRAP=ok STUB_UNSHARE=ok -- --bogus -- "$RECORD" one
  refused 2 "confine-tests: unknown flag: --bogus"
  [ "${stderr_lines[1]}" = "Usage: $SCRIPT [--no-loopback] -- <test command...>" ]
  confine "bwrap unshare ip" STUB_BWRAP=ok STUB_UNSHARE=ok -- "$RECORD" one
  [ "$status" -eq 2 ]
  [[ "${stderr_lines[1]}" == "Usage: "* ]]
  calls bwrap 0 unshare 0 child 0
}

@test "with a primitive available, no command is a usage error (exit 2)" {
  local args
  for args in "" "--" "--no-loopback --"; do
    # shellcheck disable=SC2086  # zero to two flags, split on purpose
    confine "bwrap unshare" STUB_BWRAP=ok STUB_UNSHARE=ok -- $args
    [ "$status" -eq 2 ]
    [ "${stderr_lines[-1]}" = "confine-tests: nothing to run. Usage: $SCRIPT -- <test command...>" ]
    [ -z "$output" ]
  done
  # Probes only (one of unshare, for --no-loopback): nothing was asked to run.
  calls bwrap 3 unshare 1
}

@test "--help and -h print the header comment only, exit 0, and try no primitive" {
  local flag
  for flag in --help -h; do
    # No mode is set, so any call of a stand-in would fail the test.
    confine "bwrap unshare ip" -- "$flag"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Run a test command with the network denied at the kernel level." ]
    [[ "$output" == *"scripts/confine-tests.sh --probe"* ]]
    # Not the shebang, and nothing from below the header.
    [[ "$output" != *'#!'* && "$output" != *"set -euo pipefail"* && "$output" != *"preflight"* ]]
    [ -z "$stderr" ]
  done
  calls bwrap 0 unshare 0
}

@test "--probe reports bwrap when bwrap works, consults nothing else, and runs no command given with it" {
  confine "bwrap unshare ip" STUB_BWRAP=ok STUB_UNSHARE=ok -- --probe -- "$RECORD" one
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "confine-tests: primitive available: bwrap (loopback=1)" ]
  [ -z "$stderr" ]
  calls bwrap 1
  call bwrap 1 --ro-bind / / --unshare-net -- true
  calls unshare 0 child 0
}

@test "a bwrap run hands bwrap the whole profile, then each word of the command as its own argv element" {
  confine "bwrap unshare ip" STUB_BWRAP=ok STUB_UNSHARE=ok -- -- "$RECORD" "${TRICKY[@]}"
  [ "$status" -eq 0 ]
  [ "$stderr" = "confine-tests: denying network via bwrap (loopback=1)" ]
  [ -z "$output" ]
  calls bwrap 2
  call bwrap 2 "${PROFILE[@]}" "$RECORD" "${TRICKY[@]}"
  # The command's path holds a space; its arguments arrive unchanged, and the
  # script took none of them (--probe, --no-loopback, --) for its own.
  calls child 1
  call child 1 "${TRICKY[@]}"
  [ ! -e pwned ]
  calls unshare 0 ip 0
}

@test "a bwrap run passes a command whose name starts with a dash, and the command's exit status" {
  confine "bwrap" STUB_BWRAP=ok CHILD_EXIT=7 -- -- -record -x
  [ "$status" -eq 7 ]
  call bwrap 2 "${PROFILE[@]}" -record -x
  calls child 1
  call child 1 -x
}

@test "a bwrap that fails at run time fails the run: no fallback to unshare, nothing run unconfined" {
  # The probe asks bwrap for less than the run does, so the two can disagree.
  confine "bwrap unshare ip" STUB_BWRAP=run-fails STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" one
  [ "$status" -ne 0 ]
  calls bwrap 2 unshare 0 child 0
}

@test "--no-loopback switches from bwrap to unshare and warns about what is lost, in either flag order" {
  local flags
  for flags in "--no-loopback --probe" "--probe --no-loopback"; do
    # shellcheck disable=SC2086  # two flags, split on purpose
    confine "bwrap unshare" STUB_BWRAP=ok STUB_UNSHARE=ok -- $flags
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "confine-tests: primitive available: unshare (loopback=0)" ]
    [ "${stderr_lines[0]}" = "$LO_WARNING" ]
    [[ "$stderr" == *"denies the network and NOTHING ELSE"* ]]
  done
}

@test "a --no-loopback run goes to unshare directly: no sh, no ip, the command after --" {
  confine "bwrap unshare ip" STUB_BWRAP=ok STUB_UNSHARE=ok CHILD_EXIT=7 -- \
    --no-loopback -- "$RECORD" "${TRICKY[@]}"
  [ "$status" -eq 7 ]
  [ "${stderr_lines[0]}" = "$LO_WARNING" ]
  [ "${stderr_lines[-1]}" = "confine-tests: denying network via unshare (loopback=0)" ]
  [ -z "$output" ]
  calls bwrap 1 unshare 2
  call unshare 1 -rn true
  call unshare 2 -rn -- "$RECORD" "${TRICKY[@]}"
  calls ip 0 child 1
  call child 1 "${TRICKY[@]}"
  [ ! -e pwned ]
}

@test "--no-loopback is refused (exit 2), probe or run, when bwrap works and unshare does not" {
  local stubs
  for stubs in "bwrap" "bwrap unshare"; do
    confine "$stubs" STUB_BWRAP=ok STUB_UNSHARE=refused -- --no-loopback --probe
    refused 2 "$NO_LO_OVER_BWRAP"
    confine "$stubs" STUB_BWRAP=ok STUB_UNSHARE=refused -- --no-loopback -- "$RECORD" one
    refused 2 "$NO_LO_OVER_BWRAP"
    # The way forward it names keeps the confinement: drop the flag.
    [[ "$stderr" == *"Re-run without"* ]]
  done
  calls child 0
}

@test "--probe reports unshare when bwrap is not installed, or is installed and refused" {
  confine "unshare ip" STUB_UNSHARE=ok -- --probe
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "confine-tests: primitive available: unshare (loopback=1)" ]
  [ -z "$stderr" ]
  call unshare 1 -rn true
  confine "bwrap unshare ip" STUB_BWRAP=refused STUB_UNSHARE=ok -- --probe
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "confine-tests: primitive available: unshare (loopback=1)" ]
  calls bwrap 1 unshare 2 ip 0
}

@test "unshare without ip is refused (exit 3), probe or run, and serves --no-loopback" {
  confine "unshare" STUB_UNSHARE=ok -- --probe
  refused 3 "$NO_IP"
  confine "unshare" STUB_UNSHARE=ok -- -- "$RECORD" one
  refused 3 "$NO_IP"
  [[ "$stderr" == *"--no-loopback"* ]]
  calls child 0
  confine "unshare" STUB_UNSHARE=ok -- --no-loopback --probe
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "confine-tests: primitive available: unshare (loopback=0)" ]
  confine "unshare" STUB_UNSHARE=ok -- --no-loopback -- -record -x
  [ "$status" -eq 0 ]
  # One probe per invocation (there is no bwrap to switch from), then the run.
  calls unshare 5
  call unshare 5 -rn -- -record -x
  calls child 1
  call child 1 -x
}

@test "an unshare run raises lo, then execs the command: a static sh body, every word a positional argument" {
  local first=() second=()
  confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" "${TRICKY[@]}"
  [ "$status" -eq 0 ]
  [ "$stderr" = "confine-tests: denying network via unshare (loopback=1)" ]
  [ -z "$output" ]
  call ip 1 link set lo up
  calls child 1
  call child 1 "${TRICKY[@]}"
  [ ! -e pwned ]
  # unshare -rn -- sh -c BODY sh COMMAND...
  mapfile -d '' -t first < "$LOG/unshare.2"
  call unshare 2 -rn -- sh -c "${first[4]}" sh "$RECORD" "${TRICKY[@]}"
  # BODY is the same text whatever the command (decision 018's pattern): no
  # part of the command is spliced into what sh parses. The command's exit
  # status comes back through sh.
  confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok CHILD_EXIT=7 -- -- "$RECORD" other words
  [ "$status" -eq 7 ]
  mapfile -d '' -t second < "$LOG/unshare.4"
  call unshare 4 -rn -- sh -c "${second[4]}" sh "$RECORD" other words
  [ -n "${first[4]}" ]
  [ "${first[4]}" = "${second[4]}" ]
  [[ "${first[4]}" != *"$RECORD"* && "${first[4]}" != *pwned* && "${first[4]}" != *"two words"* ]]
  calls ip 2
  call child 2 other words
}

@test "an unshare run is refused (exit 3) and the command not run when lo cannot be raised" {
  confine "unshare ip" STUB_UNSHARE=ok STUB_IP=fails -- -- "$RECORD" one
  [ "$status" -eq 3 ]
  [ "${stderr_lines[-1]}" = "confine-tests: failed to bring loopback up inside the namespace." ]
  [ -z "$output" ]
  calls ip 1 child 0
}
