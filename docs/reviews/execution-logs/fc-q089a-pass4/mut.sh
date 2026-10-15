#!/usr/bin/env bash
# Mutation probe for the strict canonical-source test (fact-check pass 4, fa059477).
# Run: mut.sh <probe-root>. Each mutant is a copy of the fa059477 tree under <probe-root>/mut/<name>.
# Bodies go inside a never-called function appended to cc-exit-scan.sh (so sourcing runs nothing),
# except where a mutant says it edits a real line or another file.
set -u
P="$1"; [ -d "$P/head" ] || { echo "no $P/head"; exit 2; }
cd "$P" || exit 2
LOG="$P/mut"; mkdir -p "$LOG"
prep() { local d="$P/mut/$1"; rm -rf "$d"; mkdir -p "$d/test"; cp -r "$P/head/devcontainer-config" "$d/"; cp "$P/head/test/cc-isolated-functions.bats" "$d/test/"; echo "$d"; }
runt() {
  local name="$1" d="$P/mut/$1"
  if HOME="$P/home" CLAUDE_DEVC_CONFIG_DIR="$P/cfg" TMPDIR="$P/tmp" timeout 120 \
       bats -f 'every file an entry point sources' "$d/test/cc-isolated-functions.bats" > "$P/mut/$name.out" 2>&1; then
    echo "$name: TEST PASSES (form not caught)"
  else
    echo "$name: test fails (caught) -- $(grep -m1 -E 'non-canonical|unchecked|not a host tool|parse missed' "$P/mut/$name.out")"
  fi
}
fn() { local d; d="$(prep "$1")"; printf '\n__probe_mut() {\n%s\n}\n' "$2" >> "$d/devcontainer-config/cc-exit-scan.sh"; runt "$1"; }
top() { local d; d="$(prep "$1")"; printf '\n%s\n' "$2" >> "$d/devcontainer-config/cc-exit-scan.sh"; runt "$1"; }

echo "## controls"
runt_clean() { local d; d="$(prep CLEAN)"; runt CLEAN; }; runt_clean
fn K1-linestart 'source "$EVIL"'
echo "## forms named in the brief"
fn N1-and-dot 'true && . "$EVIL"'
fn N2-or-source 'false || source "$EVIL"'
fn N3-brace-dot '{ . "$EVIL"; }'
fn N4-cont-dot 'true \
  && . "$EVIL"'
fn N5-cont-source-word 'source \
  "$EVIL"'
fn N6-heredoc-source 'cat <<TXT
source this text
TXT'
fn N7-dbl-bracket-string '[[ "$x" == "source" ]]'
echo "## other forms"
fn O1-backslash-dot '\. "$EVIL"'
fn O2-quoted-dot '"." "$EVIL"'
fn O3-squoted-source "s'o'urce \"\$EVIL\""
fn O4-dquote-split 'so""urce "$EVIL"'
fn O5-assign-prefix-dot 'FOO=1 . "$EVIL"'
fn O6-case-arm-dot 'case x in x) . "$EVIL" ;; esac'
fn O7-time-p-dot 'time -p . "$EVIL"'
fn O8-command-p-dot 'command -p . "$EVIL"'
fn O9-ansi-c "\$'\\x73ource' \"\$EVIL\""
fn O10-var-cmd 'c=sour; c+=ce; $c "$EVIL"'
fn O11-hash-line-in-string 'x="
#"; . "$EVIL"'
fn O12-coproc-dot 'coproc . "$EVIL"'
fn O13-tab-dot "$(printf 'true;\t. "$EVIL"')"
fn O14-noglob-dot-bracket '. "$EVIL" ]'
echo "## canonical-looking lines that name the wrong file (inside the never-called function; cc-evil.sh exists as an empty sibling)"
fnx() { local d; d="$(prep "$1")"; : > "$d/devcontainer-config/cc-evil.sh"; [ -n "${3:-}" ] && eval "$3"; printf '\n__probe_mut() {\n%s\n}\n' "$2" >> "$d/devcontainer-config/cc-exit-scan.sh"; runt "$1"; }
CAN='source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")'
fnx C1-canon-nonhost "$CAN/cc-evil.sh\""
fnx C2-canon-push "$CAN/cc-push.sh\""
fnx C3-host-but-unlisted "$CAN/cc-evil.sh\"" 'sed -i "s|^  echo \"cc-push.sh\"\$|  echo \"cc-push.sh\"\n  echo \"cc-evil.sh\"|" "$d/devcontainer-config/cc-isolated.sh"; grep -c "echo \"cc-evil.sh\"" "$d/devcontainer-config/cc-isolated.sh"'
fnx C4-listed-not-host "$CAN/cc-evil.sh\"" 'sed -i "s|cc-exit-scan.sh cc-gitdir.sh)\"; then|cc-exit-scan.sh cc-gitdir.sh cc-evil.sh)\"; then|" "$d/devcontainer-config/cc-isolated.sh"; grep -c "cc-gitdir.sh cc-evil.sh" "$d/devcontainer-config/cc-isolated.sh"'
fnx C5-listed-and-host "$CAN/cc-evil.sh\"" 'sed -i "s|cc-exit-scan.sh cc-gitdir.sh)\"; then|cc-exit-scan.sh cc-gitdir.sh cc-evil.sh)\"; then|; s|^  echo \"cc-push.sh\"\$|  echo \"cc-push.sh\"\n  echo \"cc-evil.sh\"|" "$d/devcontainer-config/cc-isolated.sh"'
fnx C6-canon-parent 'source "$CC_ISOLATED_DIR/../cc-gitdir.sh"'
fnx C7-canon-push-dir-from-scan 'source "$CC_PUSH_DIR/cc-gitdir.sh"'
fnx C8-canon-missing-file "$CAN/cc-nosuch.sh\""
echo "## done"
