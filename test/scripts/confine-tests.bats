#!/usr/bin/env bats
# @category slow
# shellcheck disable=SC2154  # bats' `run --separate-stderr` sets $stderr and $stderr_lines
# scripts/confine-tests.sh: the probe verdict, the refusal to run tests
# unconfined, usage errors, primitive selection, and that each word of the test
# command reaches the child as its own argv element.
#
# WHAT THESE TESTS DO NOT SHOW. Every test but one runs the script on a PATH
# built here: the real bash, cat and awk, plus stand-ins for bwrap, unshare and
# ip (no sh: the script runs none, and two tests add one to show it makes no
# difference). A stand-in creates no namespace, so nothing here shows that the
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
# The whole --no-loopback warning, byte for byte what the script printed
# before the fallback came to share its text: a --probe prints it too, and a
# probe's output is not to change.
LO_WARNING_TEXT="$LO_WARNING
  It denies the network and NOTHING ELSE. bwrap's read-only rootfs, its
  private /tmp and its pid namespace are all absent, and your tests run
  as uid 0 in a user namespace: a stray write that bwrap would refuse
  with EROFS will succeed against the real filesystem. Drop the flag to
  get the hardened profile (loopback is not egress — the namespace has
  no route off the host)."
NO_BWRAP_WARNING='confine-tests: WARNING — bwrap is not installed; falling back to the unshare primitive.'
BWRAP_UNUSABLE_WARNING='confine-tests: WARNING — bwrap is unusable here; falling back to the unshare primitive.'
UNSHARE_BANNER='confine-tests: denying network via unshare (loopback=1)'
BODY_NAME='confine-tests: unshare body'
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
  for tool in bash cat awk; do
    ln -s "$(type -P "$tool")" "$TOOLS/$tool"
  done
  # The test command: it records its argv as "child" and its pid, and exits
  # $CHILD_EXIT. One copy has a space in its path; two are on PATH, under a
  # name starting "-" and under the name of a shell builtin.
  printf '%s\n' '#!/usr/bin/env bash' 'set -u' 'name=child' "$RECORD_CALL" \
    'echo "$$" > "$STUB_LOG/child-pid"' 'exit "${CHILD_EXIT:-0}"' > "$RECORD"
  cp "$RECORD" "$TOOLS/-record"
  cp "$RECORD" "$TOOLS/eval"
  write_stub
  for tool in bwrap unshare ip; do cp "$T/stub/stub" "$T/stub/$tool/$tool"; done
  chmod +x "$RECORD" "$TOOLS/-record" "$TOOLS/eval" "$T"/stub/*/*
  # The profile the script hands bwrap for a run; the test command follows it.
  PROFILE=(--ro-bind / / --dev /dev --proc /proc --tmpfs /tmp --setenv TMPDIR /tmp
           --bind "$WORK" "$WORK" --unshare-net --unshare-pid --die-with-parent
           --chdir "$WORK" --)
  cd "$WORK" || return 1
}

teardown() {
  # bats shows the failing line, not what `run` captured or the stand-ins saw.
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

# confine [-STATUS] "STUB..." [VAR=value...] -- [ARG...]: run the script with
# ARGs in an empty environment whose PATH holds the named stand-ins (of bwrap,
# unshare, ip) and the real tools. Fails the test when a stand-in got a call
# it does not accept, or when -STATUS is given and is not the exit status
# (bats' `run -N`; it warns about a 127 it was not told to expect). The
# script's pid goes to $LOG/script-pid (bash and env exec, so it is the same).
confine() {
  local path="$TOOLS" tool assigns=() want=()
  if [[ "$1" == -[0-9]* ]]; then want=("$1"); shift; fi
  for tool in $1; do path="$T/stub/$tool:$path"; done
  shift
  while [[ $# -gt 0 && "$1" != -- ]]; do assigns+=("$1"); shift; done
  shift
  run "${want[@]}" --separate-stderr bash -c 'echo "$$" > "$1"; shift; exec "$@"' _ "$LOG/script-pid" \
    env -i PATH="$path" HOME="$T" TMPDIR="$T" STUB_LOG="$LOG" "${assigns[@]}" "$SCRIPT" "$@"
  [[ ! -e "$LOG/unexpected" ]]
}

# same_process: the test command ran as the process the script was. No step
# between them forked: the script execs its primitive, and its shell body
# execs the command. (The stand-in execs the command too; what a real
# primitive does with it is not tested.) This cannot see the body's own exec:
# the body runs under bash, which runs the last command of a -c string in
# place with or without it. The test with a command named eval sees it.
same_process() {
  cmp -s "$LOG/script-pid" "$LOG/child-pid" || { echo "the command was not exec'd all the way"; return 1; }
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
  # A real primitive that stalls ends in timeout's 124, which fails the test.
  run --separate-stderr timeout 60 "$SCRIPT" --probe
  case "$status" in
    0) [[ "${lines[0]}" =~ ^confine-tests:\ primitive\ available:\ (bwrap|unshare)\ \(loopback=1\)$ ]] ;;
    3)
      [[ "${stderr_lines[0]}" == "$NO_PRIMITIVE" || "${stderr_lines[0]}" == "$NO_IP" ]]
      [ -z "$output" ]
      run --separate-stderr timeout 60 env STUB_LOG="$LOG" "$SCRIPT" -- "$RECORD" one
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
  # How many probes came first is not pinned (research doc, O3). A run with no
  # command would reach a stand-in as a call it does not accept, and confine()
  # would have failed the test.
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
  same_process
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
    [ "$stderr" = "$LO_WARNING_TEXT" ]
  done
}

@test "a --no-loopback run goes to unshare directly: no sh, no ip, the command after --" {
  confine "bwrap unshare ip" STUB_BWRAP=ok STUB_UNSHARE=ok CHILD_EXIT=7 -- \
    --no-loopback -- "$RECORD" "${TRICKY[@]}"
  [ "$status" -eq 7 ]
  [ "${stderr_lines[0]}" = "$LO_WARNING" ]
  [[ "$stderr" == *"confine-tests: denying network via unshare (loopback=0)"* ]]
  [ -z "$output" ]
  calls bwrap 1 unshare 2
  call unshare 1 -rn true
  call unshare 2 -rn -- "$RECORD" "${TRICKY[@]}"
  calls ip 0 child 1
  call child 1 "${TRICKY[@]}"
  [ ! -e pwned ]
  same_process
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

@test "--probe reports unshare when bwrap is not installed, or is installed and unusable" {
  # A probe's output is its verdict alone: the fallback's warning belongs to
  # a run (see the test of it below).
  confine "unshare ip" STUB_UNSHARE=ok -- --probe
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "confine-tests: primitive available: unshare (loopback=1)" ]
  [ -z "$stderr" ]
  call unshare 1 -rn true
  confine "bwrap unshare ip" STUB_BWRAP=refused STUB_UNSHARE=ok -- --probe
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "confine-tests: primitive available: unshare (loopback=1)" ]
  [ -z "$stderr" ]
  calls bwrap 1 unshare 2 ip 0
}

@test "unshare without ip is refused (exit 3), probe or run, and serves --no-loopback" {
  # The refusal is stderr's first line: nothing is about to run, so the
  # fallback's warning is not printed before it.
  confine "unshare" STUB_UNSHARE=ok -- --probe
  refused 3 "$NO_IP"
  confine "unshare" STUB_UNSHARE=ok -- -- "$RECORD" one
  refused 3 "$NO_IP"
  [[ "$stderr" == *"--no-loopback"* ]]
  calls child 0
  confine "unshare" STUB_UNSHARE=ok -- --no-loopback --probe
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "confine-tests: primitive available: unshare (loopback=0)" ]
  [ -z "$stderr" ]
  confine "unshare" STUB_UNSHARE=ok -- --no-loopback -- -record -x
  [ "$status" -eq 0 ]
  # The flag did not cause the weaker profile here (there is no bwrap to drop
  # it for), so the warning is the fallback's, not the flag's; and its way
  # back names both steps, since bwrap alone could not serve the flag.
  [ "${stderr_lines[0]}" = "$NO_BWRAP_WARNING" ]
  [ "${stderr_lines[5]}" = "  (bubblewrap) and drop --no-loopback to get the hardened profile." ]
  # One probe per invocation (there is no bwrap to switch from), then the run.
  calls unshare 5
  call unshare 5 -rn -- -record -x
  calls child 1
  call child 1 -x
}

@test "an unshare run raises lo, then execs the command: a static bash body, every word a positional argument" {
  local first=() second=()
  confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" "${TRICKY[@]}"
  [ "$status" -eq 0 ]
  [ "${stderr_lines[-1]}" = "$UNSHARE_BANNER" ]
  [ -z "$output" ]
  call ip 1 link set lo up
  calls child 1
  call child 1 "${TRICKY[@]}"
  [ ! -e pwned ]
  same_process
  # unshare -rn -- BASH -c BODY NAME COMMAND..., where BASH is the bash that
  # runs the script (here the one on the built PATH), not sh: what exec does
  # with a word starting "-" depends on which shell sh is. NAME is the body's
  # $0, which bash puts before its own error messages.
  mapfile -d '' -t first < "$LOG/unshare.2"
  call unshare 2 -rn -- "$TOOLS/bash" -c "${first[4]}" "$BODY_NAME" "$RECORD" "${TRICKY[@]}"
  # BODY is the same text whatever the command (decision 018's pattern): no
  # part of the command is spliced into what bash parses. The command's exit
  # status comes back through bash.
  confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok CHILD_EXIT=7 -- -- "$RECORD" other words
  [ "$status" -eq 7 ]
  mapfile -d '' -t second < "$LOG/unshare.4"
  call unshare 4 -rn -- "$TOOLS/bash" -c "${second[4]}" "$BODY_NAME" "$RECORD" other words
  [ -n "${first[4]}" ]
  [ "${first[4]}" = "${second[4]}" ]
  [[ "${first[4]}" != *"$RECORD"* && "${first[4]}" != *pwned* && "${first[4]}" != *"two words"* ]]
  calls ip 2
  call child 2 other words
}

# dash_named_on_unshare SHELL: an unshare run with SHELL on PATH as sh. bash's
# exec takes options (-a NAME sets argv[0]) and dash's takes none, so a body
# that ends `exec "$@"` under sh runs `-a x CMD one` as CMD where sh is bash.
dash_named_on_unshare() {
  ln -s "$1" "$TOOLS/sh"
  confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok CHILD_EXIT=7 -- -- -record -x
  [ "$status" -eq 7 ]
  calls child 1
  call child 1 -x
  same_process
  # No file is named -a, so nothing runs: not the later word that names one.
  confine -127 "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- -a x "$RECORD" one
  [[ "${stderr_lines[-1]}" == "$BODY_NAME: line "*": exec: -a: not found" ]]
  [ -z "$output" ]
  calls child 1
}

@test "an unshare run passes a command whose name starts with a dash, and fails on one that names no file: sh is bash" {
  dash_named_on_unshare "$(type -P bash)"
}

@test "an unshare run passes a command whose name starts with a dash, and fails on one that names no file: sh is dash" {
  local dash
  dash="$(type -P dash)" || skip "dash is not installed on this machine"
  dash_named_on_unshare "$dash"
}

@test "an unshare run execs the file the command names, not a shell builtin of that name" {
  # Without exec, `eval WORD` would run WORD as shell code inside the body.
  confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- eval 'touch pwned'
  [ "$status" -eq 0 ]
  calls child 1
  call child 1 'touch pwned'
  [ ! -e pwned ]
}

# The naming half of constraint H2 (a degraded primitive "refuses and names
# what went unenforced"): the run is kept, by the brief, and says what it lacks.
@test "a run that falls back to unshare first warns what unshare does not confine, in --no-loopback's words" {
  local shared
  # The warning --no-loopback has always printed, unchanged, then the banner.
  confine "bwrap unshare" STUB_BWRAP=ok STUB_UNSHARE=ok -- --no-loopback -- "$RECORD" one
  [ "$stderr" = "$LO_WARNING_TEXT"$'\n'"confine-tests: denying network via unshare (loopback=0)" ]
  # What every route says after its own headline: all of that warning up to
  # the way back to bwrap's profile, which starts mid-line and differs.
  shared="${LO_WARNING_TEXT#*$'\n'}"
  shared="${shared%% Drop the flag to*}"
  [[ "$shared" == *"denies the network and NOTHING ELSE"* && "$shared" == *"read-only rootfs"* ]]
  [[ "$shared" == *"private /tmp"* && "$shared" == *"pid namespace"* && "$shared" == *"uid 0"* ]]
  # bwrap not installed: the fallback's headline, the same text, its own way
  # back, then the banner; all on stderr, once; and the run goes ahead.
  confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok CHILD_EXIT=7 -- -- "$RECORD" one
  [ "$status" -eq 7 ]
  [ "$stderr" = "$NO_BWRAP_WARNING
$shared Install bwrap
  (bubblewrap) to get the hardened profile.
$UNSHARE_BANNER" ]
  [ -z "$output" ]
  # bwrap installed and unusable: the headline and the way back say so.
  confine "bwrap unshare ip" STUB_BWRAP=refused STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" one
  [ "$status" -eq 0 ]
  [ "$stderr" = "$BWRAP_UNUSABLE_WARNING
$shared Run on a host
  where bwrap works to get the hardened profile.
$UNSHARE_BANNER" ]
  # The same with --no-loopback: bwrap alone would not serve the flag, so the
  # way back names both steps (the not-installed case is in the test above).
  confine "bwrap unshare" STUB_BWRAP=refused STUB_UNSHARE=ok -- --no-loopback -- "$RECORD" one
  [ "$stderr" = "$BWRAP_UNUSABLE_WARNING
$shared Run on a host
  where bwrap works and drop --no-loopback to get the hardened profile.
confine-tests: denying network via unshare (loopback=0)" ]
  calls child 4
  # With nothing to run there is nothing to warn about.
  confine "unshare ip" STUB_UNSHARE=ok -- --
  [ "$status" -eq 2 ]
  [ "$stderr" = "confine-tests: nothing to run. Usage: $SCRIPT -- <test command...>" ]
}

@test "an unshare run is refused (exit 3) and the command not run when lo cannot be raised" {
  confine "unshare ip" STUB_UNSHARE=ok STUB_IP=fails -- -- "$RECORD" one
  [ "$status" -eq 3 ]
  [ "${stderr_lines[-1]}" = "confine-tests: failed to bring loopback up inside the namespace." ]
  [ -z "$output" ]
  calls ip 1 child 0
}
