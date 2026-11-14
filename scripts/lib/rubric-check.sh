#!/usr/bin/env bash
# The rubric check build-loop.sh --check and --merge run (brief
# docs/working/briefs/2026-11-14-merge-rubric-gate.md; design in
# docs/working/research-2026-11-14-merge-rubric-gate.md). Advisory: its
# "rubric BRIEF: ..." lines never change a verdict or an exit code. Sourced by
# build-loop.sh from its own directory; rubric_lines uses that script's
# gate_git, fp_blob, MAIN_SHA and GATE_TMP and the reader lib's check_answer.

# rubric_parse FILE: one record per line, fields joined by a tab, for the
# rows of FILE's red and amber tables (skills/code-review/references/rubric.md):
#   row TIER ID CLASS STATUS QIDS
#       TIER red or amber; ID the row's first cell; CLASS fixed, closed
#       (a reference that closes it), qref (a red whose only reference is a
#       question ID: closed when one of QIDS is answered) or open; STATUS the
#       Status cell as written (markup kept, cut to 200 bytes on a character
#       boundary); QIDS the Q-NNN IDs in the Status and Author note cells.
#   bad LINE WHY
#       a table this parser cannot read by column: no Status column, or a row
#       whose cell count differs from its header's.
#   none
#       FILE has no red or amber table at all.
# A table belongs to a tier when the nearest heading above it names 🔴 or
# "Must Fix" (red), 🟡 or "Must Address" (amber); any other heading at the
# same or a higher level ends the tier, a lower one keeps it. A row ID seen
# twice in one tier keeps its last row (multi-pass rubrics append passes).
# The status is read by whole words, never substrings: a fix is a Status cell
# whose first word is "Fixed" or "Resolved" (after marks and emoji) with no
# "unresolved", "partly", "partially", "half", "not", "open", "still",
# "pending" or "reopened" anywhere in it. Anything else is a closure only by
# reference, read from the Status and Author note cells: for a red an
# override-log row ("override-log", "override row"), else an answered Q-ID
# (audit fix 6: no agent-written waiver of a red); for an amber, a qualifying
# author note: a Q-ID, an override-log row, a TODO, a roadmap item, or a
# revisit trigger ("trigger", or "revisit"/"reopen" followed by if, when,
# once or after).
rubric_parse() {
  # shellcheck disable=SC2016  # perl code, not shell
  env -u PERL_UNICODE -u PERL5OPT -u PERLIO LC_ALL=C perl -C0 -e '
    use strict; use warnings;
    binmode STDIN; binmode STDOUT;
    open(my $fh, "<:raw", $ARGV[0]) or exit 3;
    my ($tier, $tlev, $hdr, $six, $nix, @order, %rows, %byid, @bad, $tables) = (undef, 0, undef, -1, -1);
    my $n = 0;
    sub cells { my $l = shift; $l =~ s/\\\|/\//g; $l =~ s/^\s*\|//; $l =~ s/\|\s*$//; return map { my $c = $_; $c =~ s/^\s+|\s+$//g; $c } split(/\|/, $l, -1); }
    sub plain { my $c = lc shift; $c =~ s/[*_`]//g; $c =~ s/^\s+|\s+$//g; return $c; }
    sub cut { my $s = shift; $s =~ tr/\t/ /; return $s if length($s) <= 200; $s = substr($s, 0, 200); $s =~ s/[\x80-\xBF]*[\xC0-\xFF][\x80-\xBF]*\z// if $s =~ /[\x80-\xFF]\z/; return $s . "..."; }
    sub classify {
      my ($tier, $st, $note) = @_;
      my $w = lc $st; $w =~ s/[*_`]//g;
      my $first = ($w =~ /([a-z][a-z-]*)/) ? $1 : "";
      my $head = $w; $head =~ s/(:|;|\.\s|\xE2\x80\x94|\s-\s).*//s;  # the first clause
      my $neg = $head =~ /\b(unresolved|partly|partially|half|not|open|still|pending|reopened)\b/;
      return ("fixed", "") if ($first eq "fixed" || $first eq "resolved" || $first eq "corrected") && !$neg;
      my $t = "$st $note";
      my %q; $q{$1} = 1 while $t =~ /\b(Q-[0-9]{3,})\b/g;
      my $qids = join(" ", sort keys %q);
      my $ovr = $t =~ /\boverride[- ](log|rows?)\b|\baccepted-immutable\b|\brows? [0-9]+\b/i;
      if ($tier eq "red") { return ("closed", $qids) if $ovr; return ($qids ne "" ? "qref" : "open", $qids); }
      return ("closed", $qids) if $qids ne "" || $ovr || $t =~ /\bTODO\b/ || $t =~ /\broadmap\b/i
        || $t =~ /\btrigger(s|ed)?\b/i || $t =~ /\b(revisit|reopen)\s+(if|when|once|after)\b/i;
      return ("open", $qids);
    }
    my $RED = qr/\xF0\x9F\x94\xB4/; my $AMB = qr/\xF0\x9F\x9F\xA1/;
    my $tix = -1;
    while (my $l = <$fh>) {
      $n++; $l =~ s/\r?\n\z//;
      if ($l =~ /^(#{1,6})\s/) {
        my $lev = length $1; my $h = lc $l;
        my $t = ($l =~ $RED || $h =~ /must fix/) ? "red" : ($l =~ $AMB || $h =~ /must address/) ? "amber" : undef;
        if (defined $t) { $tier = $t; $tlev = $lev; } elsif (defined $tier && $lev <= $tlev) { $tier = undef; }
        $hdr = undef; next;
      }
      if ($l !~ /^\s*\|/) { $hdr = undef; next; }
      my @c = cells($l);
      if (!defined $hdr) {
        $hdr = scalar @c; $six = -1; $nix = -1; $tix = -1;
        for my $i (0 .. $#c) { my $p = plain($c[$i]); $six = $i if $p eq "status"; $nix = $i if $p eq "author note"; $tix = $i if $p eq "tier"; }
        # A table is read when a heading gives its tier, or its own Tier column does.
        if (!defined $tier && $tix < 0) { $hdr = 0; next; }
        $tables++;
        push @bad, "$n\ta " . ($tix >= 0 ? "Tier" : $tier) . " table has no Status column" if $six < 0;
        next;
      }
      next if !$hdr || $six < 0;
      next if join("", @c) =~ /^[\s:|-]*\z/;          # the separator row
      my $id = plain($c[0]);
      next if $id eq "" || $id =~ /^(\xE2\x80\x94|-|none|n\/a)$/;  # a "\xE2\x80\x94 | None" placeholder row
      if (@c != $hdr) { push @bad, "$n\trow $c[0] has " . scalar(@c) . " cells where its header has $hdr"; next; }
      my $rt = $tier;
      if ($tix >= 0) {
        my $tc = $c[$tix]; my $tp = plain($tc);
        $rt = ($tc =~ $RED || $tp =~ /^red\b/) ? "red" : ($tc =~ $AMB || $tp =~ /^(amber|yellow)\b/) ? "amber" : undef;
        next unless defined $rt;
      }
      my ($cl, $q) = classify($rt, $c[$six], $nix >= 0 ? $c[$nix] : "");
      my $k = "$rt\t$c[0]";
      push @order, $k unless exists $rows{$k};
      $rows{$k} = [$rt, $c[0], $cl, cut($c[$six]), $q, $c[$six]];
      $byid{$c[0]} = $k;
    }
    # A row not fixed that names another row of this file as its successor
    # ("superseded by C1", "still open as A22", "composed \xE2\x86\x92 X1") takes
    # the class of that row, followed up to 5 hops; an unknown name changes nothing.
    for my $k (@order) {
      my $r = $rows{$k}; next if $r->[2] eq "fixed";
      my ($cur, $hops, %seen) = ($r, 0);
      while ($hops++ < 5 && $cur->[5] =~ /(?:superseded by|\bas|\binto|\bsee|\xE2\x86\x92)\s*\**([A-Z]{1,3}[0-9]+[a-z0-9]*)\b/) {
        my $t = $byid{$1}; last if !defined $t || $seen{$t}++ || $t eq $k;
        $cur = $rows{$t}; last if $cur->[2] ne "open" || $cur->[5] !~ /(?:superseded by|\bas|\binto|\bsee|\xE2\x86\x92)/;
      }
      $r->[2] = $cur->[2] if $cur != $r && $cur->[2] ne "qref";
    }
    print join("\t", "row", @{$rows{$_}}[0 .. 4]), "\n" for @order;
    print "bad\t$_\n" for @bad;
    print "none\n" unless $tables;
  ' "$1"
}

# rubric_lines BRIEF BRANCH TIP: the advisory "rubric BRIEF: ..." lines for
# check_line, from committed objects alone. It reads check_line's ps and ss
# (each changed path and its status letter; bash scope is dynamic) and the
# rubrics among them: a file added or changed under docs/reviews/ whose name
# holds "code-review-rubric" and ends .md. Of the canonical names
# (code-review-rubric-DATE-SLUG.md) only the newest DATE per SLUG is read, the
# loop's rubric as skills/code-review/SKILL.md finds it; an older one gets a
# superseded line. Each line, in this order per rubric:
#   open PATH ID TIER: STATUS   a red or amber row neither fixed nor closed
#   unread PATH[ line N]: WHY   a table or file the parser cannot read
#   stale PATH: K fix(...) commits on BRANCH follow its last change in SHA12
#   clean PATH: R red and A amber rows, none open
# or, with no rubric, one "none: WHY" line (code outside docs/, or not).
# shellcheck disable=SC2154  # ps and ss are check_line's locals, read by dynamic scope
rubric_lines() {
  local a="$1" br="$2" sha="$3" i p b f k d code=0 last nfix out tier id cl st q x ok nred namb
  local -A newest=() qdone=()
  local files=() rows=() sup=()
  for i in "${!ps[@]}"; do
    p="${ps[$i]}"
    [[ "$p" == docs/* ]] || code=$((code + 1))
    [[ "${ss[$i]}" == [AM] && "$p" =~ ^docs/reviews/([^/]*-)?code-review-rubric[^/]*\.md$ ]] || continue
    b="${p##*/}"
    if [[ "$b" =~ ^code-review-rubric-([0-9]{4}-[0-9]{2}-[0-9]{2})-(.+)\.md$ ]]; then
      d="${BASH_REMATCH[1]}"; k="${BASH_REMATCH[2]}"
      if [[ -z "${newest[$k]-}" ]]; then newest[$k]="$p"
      else
        x="${newest[$k]##*/}"; x="${x#code-review-rubric-}"
        if [[ "$d" > "${x:0:10}" ]]; then sup+=("${newest[$k]} ${p}"); newest[$k]="$p"; else sup+=("$p ${newest[$k]}"); fi
      fi
    else files+=("$p"); fi
  done
  for k in "${!newest[@]}"; do files+=("${newest[$k]}"); done
  if [[ ${#files[@]} -eq 0 ]]; then
    if [[ ${#ps[@]} -eq 0 ]]; then echo "rubric $a: none: $br changes no path"
    elif [[ "$code" -gt 0 ]]; then echo "rubric $a: none: $br changes $code paths outside docs/ and adds or changes no code-review rubric under docs/reviews/"
    else echo "rubric $a: none: $br changes only docs/, so no rubric is needed"; fi
    return 0
  fi
  mapfile -t files < <(printf '%s\n' "${files[@]}" | LC_ALL=C sort)
  for x in "${sup[@]}"; do echo "rubric $a: superseded ${x% *} by ${x#* } (not read)"; done
  for f in "${files[@]}"; do
    i=0; fp_blob "$sha" "$f" "$GATE_TMP/rub" || i=$?
    case "$i" in
      0) ;;
      2) echo "rubric $a: unread $f: not a regular file in the tip of $br"; continue ;;
      *) echo "rubric $a: unread $f: could not be read"; continue ;;
    esac
    if ! rubric_parse "$GATE_TMP/rub" > "$GATE_TMP/rubp"; then echo "rubric $a: unread $f: could not be parsed"; continue; fi
    ok=1; nred=0; namb=0; rows=()
    while IFS=$'\t' read -r k tier id cl st q; do
      case "$k" in
        row)
          if [[ "$tier" == red ]]; then nred=$((nred + 1)); else namb=$((namb + 1)); fi
          if [[ "$cl" == qref ]]; then
            cl=open
            for x in $q; do
              if [[ -z "${qdone[$x]-}" ]]; then out="$(check_answer "$x")"; qdone[$x]=n; [[ "$out" == "open "* || "$out" == "skip "* ]] || qdone[$x]=y; fi
              [[ "${qdone[$x]}" == n ]] || cl=closed
            done
          fi
          [[ "$cl" != open ]] || { ok=""; rows+=("rubric $a: open $f $id $tier: $st"); } ;;
        bad) ok=""; rows+=("rubric $a: unread $f line $tier: $id") ;;
        none) ok=""; rows+=("rubric $a: unread $f: no red or amber table (a heading naming 🔴 Must Fix or 🟡 Must Address, or a Tier column)") ;;
      esac
    done < "$GATE_TMP/rubp"
    [[ ${#rows[@]} -eq 0 ]] || printf '%s\n' "${rows[@]}"
    if last="$(gate_git rev-list -1 "$sha" "^$MAIN_SHA" -- "$f")" && [[ -n "$last" ]] \
      && x="$(gate_git rev-list --no-commit-header --format=%s "$sha" "^$last" "^$MAIN_SHA")"; then
      nfix="$(printf '%s\n' "$x" | LC_ALL=C awk '{ if (tolower($0) ~ /^fix[(:!]/) n++ } END { print n + 0 }')"
      if [[ "$nfix" -gt 0 ]]; then ok=""; echo "rubric $a: stale $f: $nfix fix(...) commits on $br follow its last change in ${last:0:12}"; fi
    else ok=""; echo "rubric $a: unread $f: its commits on $br could not be listed, so whether fixes follow it is unknown"; fi
    [[ -z "$ok" ]] || echo "rubric $a: clean $f: $nred red and $namb amber rows, none open"
  done
}
