#!/usr/bin/env bash
# The rubric check build-loop.sh --check and --merge run (brief
# docs/working/briefs/2026-11-14-merge-rubric-gate.md; design in
# docs/working/research-2026-11-14-merge-rubric-gate.md). Advisory: its
# "rubric BRIEF: ..." lines never change a verdict or an exit code. Sourced by
# build-loop.sh from its own directory; rubric_lines uses that script's
# gate_git, fp_blob, showpath, MAIN_SHA and GATE_TMP and the reader lib's
# check_answer.

# rubric_parse FILE: one record per line, fields joined by a tab, none empty
# ("-" for no Q-IDs, "(empty)" for an empty Status cell), for the rows of
# FILE's red and amber tables (skills/code-review/references/rubric.md):
#   row TIER ID CLASS STATUS QIDS
#       TIER red or amber; ID the row's first cell; CLASS fixed, closed
#       (a reference that closes it), qref (closed only when one of QIDS is
#       answered on the default branch) or open; STATUS the Status cell as
#       written (markup kept; over 200 bytes, cut to 200 on a character
#       boundary and "..." added); QIDS the Q-NNN IDs in the Status and Author
#       note cells.
#   bad LINE WHY
#       a table or row this parser cannot read by column: no Status column,
#       a cell count that differs from its header's, a Tier cell it cannot
#       read, or a code fence left open.
#   none
#       FILE has no red or amber table at all.
# A table belongs to a tier when the nearest heading above it names 🔴 or
# "Must Fix" (red), 🟡 or "Must Address" (amber), or when it has its own Tier
# column (red, amber, yellow, a mark or the Must words; green, 🟢 and
# Consider rows are left out). Any other heading at the same or a higher level
# ends the tier, a lower one keeps it; lines inside a ``` or ~~~ fence are not
# read at all. A row ID seen twice in one tier keeps its last row
# (multi-pass rubrics append passes).
# A Status cell is read by its first word and by whole words, never
# substrings ("Unresolved" is not "resolved"). Its first word follows the
# "Status words" table that brief 2026-11-14-review-rules-close-gaps adds to
# rubric.md: "Fixed", or "Resolved" in older rubrics, is a fix unless the
# cell anywhere says unresolved, partly, partially, half, "not yet", "not
# fixed", "not resolved", "still open", pending or reopened (or its first
# clause says not, open or still). "Split" and "Carried" close a row of
# either tier with none of those words: a Split that names a roadmap item, a
# branch or a brief (a Split naming only a Q-ID is qref), a Carried whose
# newer rubric file is followed by the row ID. Any other closure of a red is
# qref: it counts only with a Q-ID the owner has answered (the orchestrator's
# correction to the brief's criterion 2: an agent can write an override-log
# row or a trigger itself, which is how the audit's U2a2 D1 red was waived).
# An amber, whatever its first word, closes on a qualifying author note
# (rubric.md's definition, which older words such as Stands or Noted also
# carry) in its Status or Author note cell, found by keyword: a Q-ID, an
# override-log row ("override-log", "override row", "row N",
# "Accepted-immutable"), a TODO, "roadmap", or a revisit trigger ("trigger",
# or revisit/reopen then if, when, once or after). Keyword presence is not a
# check that the reference exists or says what it should.
# A row not fixed whose Status names its successor row in this file
# ("superseded by C1", "→ X1") takes that row's class, followed up to 5 hops;
# a red follows only red rows, so it never borrows an amber's closure.
rubric_parse() {
  # shellcheck disable=SC2016  # perl code, not shell
  env -u PERL_UNICODE -u PERL5OPT -u PERLIO LC_ALL=C perl -C0 -e '
    use strict; use warnings;
    binmode STDIN; binmode STDOUT;
    open(my $fh, "<:raw", $ARGV[0]) or exit 3;
    my ($tier, $tlev, $hdr, $six, $nix, $tix, $fence, @order, %rows, %byid, @bad, $tables) = (undef, 0, undef, -1, -1, -1, "");
    my $n = 0;
    my $RED = qr/\xF0\x9F\x94\xB4/; my $AMB = qr/\xF0\x9F\x9F\xA1/; my $GRN = qr/\xF0\x9F\x9F\xA2/;
    my $NEG = qr/\b(unresolved|partly|partially|half|not yet|not fixed|not resolved|still open|pending|reopened)\b/;
    my $SUCC = qr/(?:superseded by|\xE2\x86\x92)\s*\**([A-Z]{1,3}[0-9]+[a-z0-9]*)\b/;
    sub cells { my $l = shift; $l =~ s/\\\|/\//g; $l =~ s/^\s*\|//; $l =~ s/\|\s*$//; return map { my $c = $_; $c =~ s/^\s+|\s+$//g; $c } split(/\|/, $l, -1); }
    sub plain { my $c = lc shift; $c =~ s/[*_`]//g; $c =~ s/^\s+|\s+$//g; return $c; }
    # cut: at most 200 bytes, never ending inside a UTF-8 sequence: a lead
    # byte whose continuation bytes do not all fit is dropped with them.
    sub cut {
      my $s = shift; $s =~ tr/\t/ /; return "(empty)" if $s eq ""; return $s if length($s) <= 200;
      $s = substr($s, 0, 200);
      if ($s =~ /([\xC0-\xFF])([\x80-\xBF]*)\z/) {
        my $need = ord($1) >= 0xF0 ? 3 : ord($1) >= 0xE0 ? 2 : 1;
        substr($s, -(1 + length $2)) = "" if length($2) < $need;
      }
      return $s . "...";
    }
    sub classify {
      my ($tier, $st, $note) = @_;
      my $w = lc $st; $w =~ s/[*_`]//g;
      my $first = ($w =~ /([a-z][a-z-]*)/) ? $1 : "";
      my $head = $w; $head =~ s/(:|;|\.\s|\xE2\x80\x94|\s-\s).*//s;  # the first clause
      my $neg = $w =~ $NEG || $head =~ /\b(not|open|still)\b/;
      return ("fixed", "-") if ($first eq "fixed" || $first eq "resolved") && !$neg;
      my $t = "$st $note";
      my %q; $q{$1} = 1 while $t =~ /\b(Q-[0-9]{3,})\b/g;
      my $qids = join(" ", sort keys %q); $qids = "-" if $qids eq "";
      if ($first eq "split" && !$neg) {
        return ("closed", $qids) if $t =~ /\b(roadmap|branch|brief)\b/i;
        return ("qref", $qids) if $qids ne "-";
      }
      return ("closed", $qids) if $first eq "carried" && !$neg && $t =~ /code-review-rubric[^\s|]*\.md\W{0,3}(row\s+)?[A-Z]{1,3}[0-9]+\b/;
      return ($qids ne "-" ? "qref" : "open", $qids) if $tier eq "red";
      my $ovr = $t =~ /\boverride[- ](log|rows?)\b|\baccepted-immutable\b|\brows? [0-9]+\b/i;
      return ("closed", $qids) if $qids ne "-" || $ovr || $t =~ /\bTODO\b/ || $t =~ /\broadmap\b/i
        || $t =~ /\btrigger(s|ed)?\b/i || $t =~ /\b(revisit|reopen)\s+(if|when|once|after)\b/i;
      return ("open", $qids);
    }
    while (my $l = <$fh>) {
      $n++; $l =~ s/\r?\n\z//;
      if ($l =~ /^\s{0,3}(```|~~~)/) { my $m = $1; if ($fence eq "") { $fence = "$m\t$n"; } elsif ($fence =~ /^\Q$m\E\t/) { $fence = ""; } $hdr = undef; next; }
      next if $fence ne "";
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
        $rt = ($tc =~ $RED || $tp =~ /^(red|must fix)\b/) ? "red" : ($tc =~ $AMB || $tp =~ /^(amber|yellow|must address)\b/) ? "amber" : undef;
        if (!defined $rt) { push @bad, "$n\trow $c[0] has a Tier cell read as no tier" unless $tc =~ $GRN || $tp =~ /^(green|consider)\b/; next; }
      }
      my ($cl, $q) = classify($rt, $c[$six], $nix >= 0 ? $c[$nix] : "");
      my $k = "$rt\t$c[0]";
      push @order, $k unless exists $rows{$k};
      $rows{$k} = [$rt, $c[0], $cl, cut($c[$six]), $q, $c[$six]];
      $byid{$c[0]}{$rt} = $k;
    }
    push @bad, (split /\t/, $fence)[1] . "\ta code fence opened here is never closed, so the lines after it are not read" if $fence ne "";
    for my $k (@order) {
      my $r = $rows{$k}; next if $r->[2] eq "fixed";
      my ($cur, $hops, %seen) = ($r, 0);
      while ($hops++ < 5 && $cur->[5] =~ $SUCC) {
        my $ids = $byid{$1} or last;
        my $t = $r->[0] eq "red" ? $ids->{red} : ($ids->{amber} // $ids->{red});
        last if !defined $t || $seen{$t}++ || $t eq $k;
        $cur = $rows{$t}; last if $cur->[2] ne "open";
      }
      ($r->[2], $r->[4]) = ($cur->[2], $cur->[4]) if $cur != $r;
    }
    print join("\t", "row", @{$rows{$_}}[0 .. 4]), "\n" for @order;
    print "bad\t$_\n" for @bad;
    print "none\n" unless $tables;
  ' "$1"
}

# rubric_lines BRIEF BRANCH TIP PATHS STATUSES: the advisory "rubric BRIEF:
# ..." lines for check_line, from committed objects alone. PATHS and STATUSES
# name check_line's arrays of the merge's changed paths and their status
# letters (namerefs). A rubric is a path added or changed directly in
# docs/reviews/ whose name starts "code-review-rubric" or holds
# "-code-review-rubric", ending .md. Of the canonical names
# (code-review-rubric-DATE-SLUG.md) only the newest DATE per SLUG is read, the
# loop's rubric as skills/code-review/SKILL.md finds it. Lines: first one
# "superseded OLD by NEW (not read)" per older file (NEW the file read), then
# per rubric read, in path order:
#   open PATH ID TIER: STATUS   a red or amber row neither fixed nor closed
#   unread PATH[ line N]: WHY   a table, row or file the parser cannot read
#   stale PATH: K fix(...) commits on BRANCH follow its last change in SHA12
#                               (commits on BRANCH, not on main, that the last
#                               commit changing PATH does not contain)
#   clean PATH: R red and A amber rows, none open
# or, with no rubric, one "none: WHY" line. A PATH outside pathform's
# characters prints as "?". A failed read is an unread line, never silence.
rubric_lines() {
  local a="$1" br="$2" sha="$3" i p b f k d code=0 last nfix out tier id cl st q x ok nred namb
  local -n rl_ps="$4" rl_ss="$5"
  local -A newest=() ndate=() qdone=()
  local files=() rows=() sup=()
  for i in "${!rl_ps[@]}"; do
    p="${rl_ps[$i]}"
    [[ "$p" == docs/* ]] || code=$((code + 1))
    [[ "${rl_ss[$i]}" == [AM] && "$p" =~ ^docs/reviews/([^/]*-)?code-review-rubric[^/]*\.md$ ]] || continue
    b="${p##*/}"
    if [[ "$b" =~ ^code-review-rubric-([0-9]{4}-[0-9]{2}-[0-9]{2})-(.+)\.md$ ]]; then
      d="${BASH_REMATCH[1]}"; k="${BASH_REMATCH[2]}"
      if [[ -z "${newest[$k]-}" ]]; then newest[$k]="$p"; ndate[$k]="$d"
      elif [[ "$d" > "${ndate[$k]}" ]]; then sup+=("$k ${newest[$k]}"); newest[$k]="$p"; ndate[$k]="$d"
      else sup+=("$k $p"); fi
    else files+=("$p"); fi
  done
  for k in "${!newest[@]}"; do files+=("${newest[$k]}"); done
  if [[ ${#files[@]} -eq 0 ]]; then
    if [[ ${#rl_ps[@]} -eq 0 ]]; then echo "rubric $a: none: $br changes no path"
    elif [[ "$code" -gt 0 ]]; then echo "rubric $a: none: $br changes $code paths outside docs/ and adds or changes no code-review rubric under docs/reviews/"
    else echo "rubric $a: none: $br changes only docs/, so no rubric is needed"; fi
    return 0
  fi
  x="$(printf '%s\n' "${files[@]}" | LC_ALL=C sort)" || { echo "rubric $a: unread: the rubrics on $br could not be sorted, so none was read"; return 0; }
  mapfile -t files <<< "$x"
  for x in "${sup[@]}"; do echo "rubric $a: superseded $(showpath "${x#* }") by $(showpath "${newest[${x%% *}]}") (not read)"; done
  for f in "${files[@]}"; do
    p="$(showpath "$f")"
    i=0; fp_blob "$sha" "$f" "$GATE_TMP/rub" || i=$?
    case "$i" in
      0) ;;
      2) echo "rubric $a: unread $p: not a regular file in the tip of $br"; continue ;;
      *) echo "rubric $a: unread $p: could not be read"; continue ;;
    esac
    if ! rubric_parse "$GATE_TMP/rub" > "$GATE_TMP/rubp"; then echo "rubric $a: unread $p: could not be parsed"; continue; fi
    ok=1; nred=0; namb=0; rows=()
    while IFS=$'\t' read -r k tier id cl st q; do
      case "$k" in
        row)
          if [[ "$tier" == red ]]; then nred=$((nred + 1)); else namb=$((namb + 1)); fi
          if [[ "$cl" == qref ]]; then
            # Closed only by an entry check_answer reads as answered on main
            # (keep, drop, done, or an answer it cannot read as an option);
            # open, a skip, empty or failed output leaves the row open.
            cl=open
            for x in $q; do
              if [[ -z "${qdone[$x]-}" ]]; then
                out="$(check_answer "$x")" || out=""; qdone[$x]=n
                case "$out" in "keep $x"|"drop $x"|"done $x"|"unrecognized $x") qdone[$x]=y ;; esac
              fi
              [[ "${qdone[$x]}" == n ]] || cl=closed
            done
          fi
          [[ "$cl" != open ]] || { ok=""; rows+=("rubric $a: open $p $id $tier: $st"); } ;;
        bad) ok=""; rows+=("rubric $a: unread $p line $tier: $id") ;;
        none) ok=""; rows+=("rubric $a: unread $p: no red or amber table (a heading naming 🔴 Must Fix or 🟡 Must Address, or a Tier column)") ;;
      esac
    done < "$GATE_TMP/rubp"
    [[ ${#rows[@]} -eq 0 ]] || printf '%s\n' "${rows[@]}"
    if last="$(gate_git rev-list -1 "$sha" "^$MAIN_SHA" -- "$f")" && [[ -n "$last" ]] \
      && x="$(gate_git rev-list --no-commit-header --format=%s "$sha" "^$last" "^$MAIN_SHA")" \
      && nfix="$(printf '%s\n' "$x" | LC_ALL=C awk '{ if (tolower($0) ~ /^fix[(:!]/) n++ } END { print n + 0 }')"; then
      if [[ "$nfix" -gt 0 ]]; then ok=""; echo "rubric $a: stale $p: $nfix fix(...) commits on $br follow its last change in ${last:0:12}"; fi
    else ok=""; echo "rubric $a: unread $p: its commits on $br could not be listed, so whether fixes follow it is unknown"; fi
    [[ -z "$ok" ]] || echo "rubric $a: clean $p: $nred red and $namb amber rows, none open"
  done
}
