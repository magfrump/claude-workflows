#!/bin/bash
# The D6 snippet (plan D6, F38-F40; U3b3): the one way the orchestrator runs
# build-loop.sh (the gate) and dev-cycle.sh (the digest). U4 puts this file,
# byte for byte, in skills/dev-cycle/SKILL.md, the root-owned image copy, as
# the body of a quoted heredoc that bash reads, so it runs the same from any
# login shell and defines nothing in the caller's:
#   bash -s -- build-loop.sh ARG... <<'D6'
#   (this file)
#   D6
# T33 is to assert the two match once U4 writes the block (pending until then).
# Run it from the repository's checkout (the orchestrator's own worktree). In
# claude-workflows (main's first-parent root commit is D6_ROOT) it runs main's
# own scripts: one perl process reads every object it uses through one
# cat-file --batch and uses an object only once its bytes hash to its id
# (main's first-parent commits to the root, the trees down to scripts/lib/, the
# four files), taking each next id from bytes it has checked, so no other
# reader or other copy of an object decides what runs; it writes the four
# files from those bytes into a fresh temp dir (a same-uid writer racing that
# 0700 dir is the Q-103 class, row 509). In any other repository (another
# root, or not SHA-1) it runs the image copy under D6_OPT, by absolute path,
# once those files and every directory above them are root-owned, no symlink
# and not writable here. It never reads the working tree, ~/.claude/scripts or
# a replaced object; it trusts refs/heads/main itself (a moved main is
# --main-log's to report, D13; F19, rows 509, 721).
# Arguments: build-loop.sh or dev-cycle.sh, then that script's own.
# Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout,
# with nothing run, for a replace ref, info/grafts, a default branch that is
# not exactly one plain main or master or whose ref names no commit itself, a
# first-parent history, tree or file that cannot be read whole or does not hash
# to its id (a shallow history among them), a script on main that is not a
# regular file, an image copy that fails the ownership checks, or a git read or
# temp-dir step that fails (git or perl may add a line on stderr); 1 for
# another first argument. Its git carries the lib's HARDEN pairs and
# git_harden's environment (G; a test pins the two lists equal). These checks
# come before, not instead of, the script's own state and default-branch gates.
d6() {
  set -u -o pipefail
  D6_ROOT=640cf00735754d4253819a0354fb8ca9b71a8ea7; D6_OPT=/opt/claude-workflows
  no() { echo "refuse d6: $*"; exit 2; }
  G=(env GIT_NO_REPLACE_OBJECTS=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none GIT_LITERAL_PATHSPECS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 git -c core.useReplaceRefs=false -c core.hooksPath=/dev/null -c core.fsmonitor=false -c core.attributesFile=/dev/null -c core.commitGraph=false -c core.multiPackIndex=false -c log.date=default -c log.showSignature=false)
  g() { "${G[@]}" "$@"; }
  own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no "$1 is not root-owned, a plain path and unwritable here"; }
  local s="${1:-}" F x m n sha f d P  # t stays global: the EXIT trap reads it
  [[ "$s" == build-loop.sh || "$s" == dev-cycle.sh ]] || { echo "d6: the first argument is build-loop.sh or dev-cycle.sh" >&2; exit 1; }
  shift
  F=(build-loop.sh dev-cycle.sh questions.sh lib/dev-cycle-read.sh)
  x="$(g for-each-ref --format='%(refname)' refs/replace/)" || no "refs/replace could not be listed"
  [[ -z "$x" ]] || no "a replace ref exists (F38)"
  x="$(g rev-parse --path-format=absolute --git-path info/grafts)" || no "the grafts path could not be read"
  [[ ! -e "$x" && ! -L "$x" ]] || no "info/grafts exists (F38)"
  m=""; for n in main master; do g show-ref --verify -q "refs/heads/$n" && m+="$n "; done
  m="${m% }"; [[ "$m" == main || "$m" == master ]] || no "the default branch is not exactly one of main and master"
  ! g symbolic-ref -q "refs/heads/$m" >/dev/null || no "refs/heads/$m is a symbolic ref"
  sha="$(g rev-parse --verify -q "refs/heads/$m")" && [[ "$(g cat-file -t "$sha")" == commit ]] || no "refs/heads/$m names no commit"
  # The verified reader (args: D6_ROOT, the temp dir, main's commit, the git
  # command). It prints "main" once the four files are written, "other" when
  # the first-parent root is not D6_ROOT; any failure dies (status 255).
  P='use strict; use IPC::Open2; use Digest::SHA qw(sha1_hex);
    my ($root, $out, $c, @git) = @ARGV; open2(my $r, my $w, @git, "cat-file", "--batch"); binmode $r; binmode $w; $w->autoflush(1);
    sub obj { my ($id, $want) = @_; print $w "$id\n"; my $h = <$r>; die "no answer for $id\n" unless defined $h; chomp $h; my ($i, $t, $s) = split / /, $h, 3; my $b = "";
      die "$id is not a whole $want\n" unless defined $s && $i eq $id && $t eq $want && $s =~ /\A[0-9]+\z/ && read($r, $b, $s) == $s && getc($r) eq "\n";
      die "$id does not hash to its id\n" unless sha1_hex("$t $s\0$b") eq $id; return $b }
    sub entry { my ($t, $n, $m) = @_; my $b = obj($t, "tree");
      while ($b =~ /\G([0-7]+) ([^\0]+)\0(.{20})/gs) { my ($md, $nm, $id) = ($1, $2, $3); next unless $nm eq $n; die "$n is not a $m entry\n" unless $md =~ $m; return unpack("H*", $id) } die "no $n in $t\n" }
    my $tree; while (1) { my ($hd) = split /\n\n/, obj($c, "commit"), 2; $tree //= $hd =~ /\Atree ([0-9a-f]{40})\n/ ? $1 : die "$c has no tree\n";
      my ($p) = $hd =~ /^parent ([0-9a-f]{40})$/m; last unless defined $p; $c = $p }
    if ($c ne $root) { print "other\n"; exit 0 }
    my $s = entry($tree, "scripts", qr/\A40000\z/); my $l = entry($s, "lib", qr/\A40000\z/);
    for my $f ("build-loop.sh", "dev-cycle.sh", "questions.sh", "lib/dev-cycle-read.sh") { my ($t, $n) = $f =~ m{\Alib/(.*)\z} ? ($l, $1) : ($s, $f);
      my $b = obj(entry($t, $n, qr/\A100(644|755)\z/), "blob"); open(my $fh, ">", "$out/scripts/$f") or die "$f: $!\n"; binmode $fh; print $fh $b; close($fh) or die "$f: $!\n" }
    print "main\n";'
  t="$(mktemp -d)" || no "mktemp failed"
  trap 'rm -rf "$t"' EXIT
  mkdir "$t/scripts" "$t/scripts/lib" || no "the temp dir could not be laid out"
  x="$(g rev-parse --show-object-format)" || no "the object format could not be read"
  # D6_ROOT is a SHA-1 id: a repository in another format is not claude-workflows.
  if [[ "$x" == sha1 ]]; then
    x="$(LC_ALL=C perl -e "$P" "$D6_ROOT" "$t" "$sha" "${G[@]}")" || no "$m's first-parent history, the trees above scripts/lib/ or the four files could not be read whole, or an object does not hash to its id"
  else x=other; fi
  if [[ "$x" == main ]]; then
    d="$t"
  elif [[ "$x" == other ]]; then
    d="$D6_OPT"
    for f in "${F[@]}"; do own "$d/scripts/$f"; [[ -f "$d/scripts/$f" ]] || no "$d/scripts/$f is not a regular file"; done
    x="$d/scripts/lib"; while own "$x"; [[ "$x" != / ]]; do x="${x%/*}"; x="${x:-/}"; done
  else no "the verified reader gave no answer"; fi
  env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"
  exit "$?"
}
# Under bash -s the script is the heredoc on stdin: bash has read this whole
# line before it runs, and no child reads the rest of it.
d6 "$@" </dev/null
