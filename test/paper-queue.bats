#!/usr/bin/env bats
# @category fast
# Contract tests for scripts/paper-queue.sh — the blocked-full-text request queue.
#
# Hermetic by construction: the script never touches the network (that is the
# whole point of it — it exists *because* the fetch is impossible inside the
# boundary), and every queue file here lives under BATS_TEST_TMPDIR via
# $PAPER_QUEUE, so nothing writes into the repo's own tree.
#
# The TSV-integrity tests matter more than they look: this repo has shipped
# field-shifting bugs before (an empty column collapsing under `IFS=$'\t' read`),
# so an identifier containing a tab or a newline is asserted against the raw
# bytes of the file, not just against the command's output.

bats_require_minimum_version 1.5.0

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    PQ="$REPO_ROOT/scripts/paper-queue.sh"
    PAPERS="$BATS_TEST_TMPDIR/papers"
    export PAPER_QUEUE="$PAPERS/requests.tsv"
}

pq() {
    run bash "$PQ" "$@"
}

# --- add ------------------------------------------------------------------

@test "add creates the queue file with a header row" {
    [ ! -f "$PAPER_QUEUE" ]

    pq add 10.1234/abc "needs full text"
    [ "$status" -eq 0 ]
    [[ "$output" == *"queued: 10.1234/abc"* ]]

    [ -f "$PAPER_QUEUE" ]
    run head -1 "$PAPER_QUEUE"
    [ "$output" = "$(printf 'date\tstatus\tidentifier\thost\tnote')" ]

    run wc -l < "$PAPER_QUEUE"
    [ "$output" -eq 2 ]
}

@test "add records status open, the identifier and the note" {
    pq add 10.1234/abc "needs full text"
    run tail -1 "$PAPER_QUEUE"
    [[ "$output" == *$'\topen\t10.1234/abc\t'*$'\tneeds full text' ]]
}

@test "add is idempotent on the identifier" {
    pq add 10.1234/abc "first note"
    [ "$status" -eq 0 ]

    pq add 10.1234/abc "a different note"
    [ "$status" -eq 0 ]
    [[ "$output" == *"already queued: 10.1234/abc"* ]]

    # Still exactly one data row, and the original note survived.
    run wc -l < "$PAPER_QUEUE"
    [ "$output" -eq 2 ]
    run grep -ac 'first note' "$PAPER_QUEUE"
    [ "$output" -eq 1 ]
}

@test "add parses the host out of a URL identifier" {
    pq add 'https://www.sciencedirect.com/science/article/pii/X1' "elsevier"
    run tail -1 "$PAPER_QUEUE"
    [[ "$output" == *$'\twww.sciencedirect.com\t'* ]]
}

@test "add strips userinfo, port and query when parsing the host" {
    pq add 'https://user@repo.example.ac.uk:8443/bitstream/1/2/paper.pdf?dl=1'
    run tail -1 "$PAPER_QUEUE"
    [[ "$output" == *$'\trepo.example.ac.uk\t'* ]]
}

@test "add leaves the host empty for a DOI or a bare arXiv id" {
    pq add 10.1234/abc
    pq add arXiv:2509.20645
    run tail -1 "$PAPER_QUEUE"
    # date, status, identifier, EMPTY host, EMPTY note -> two trailing tabs.
    [[ "$output" == *$'\tarXiv:2509.20645\t\t' ]]
}

@test "add rejects a call with no identifier" {
    pq add
    [ "$status" -eq 1 ]
    [[ "$output" == *"needs an identifier"* ]]
}

# --- field hygiene --------------------------------------------------------

@test "a tab inside a field does not add a column" {
    pq add "$(printf 'id\twith\ttab')" "$(printf 'note\twith\ttab')"
    [ "$status" -eq 0 ]

    # One data line, and it holds exactly four separators (five columns).
    run wc -l < "$PAPER_QUEUE"
    [ "$output" -eq 2 ]

    local line tabs
    line="$(tail -1 "$PAPER_QUEUE")"
    tabs="$(printf '%s' "$line" | tr -cd '\t' | wc -c)"
    [ "$tabs" -eq 4 ]
    [[ "$line" == *'id\twith\ttab'* ]]
}

@test "a newline inside a field does not add a row" {
    pq add "$(printf 'id\nwith\nnewlines')" "$(printf 'note\nwith\nnewline')"
    [ "$status" -eq 0 ]

    run wc -l < "$PAPER_QUEUE"
    [ "$output" -eq 2 ]

    run tail -1 "$PAPER_QUEUE"
    [[ "$output" == *'id\nwith\nnewlines'* ]]
    [[ "$output" == *'note\nwith\nnewline'* ]]
}

@test "an escaped identifier stays idempotent and stays findable" {
    pq add "$(printf 'id\twith\ttab')"
    pq add "$(printf 'id\twith\ttab')"
    [[ "$output" == *"already queued"* ]]

    pq "done" "$(printf 'id\twith\ttab')"
    [ "$status" -eq 0 ]
    [[ "$output" == *"fulfilled:"* ]]
    run grep -ac $'\tfulfilled\t' "$PAPER_QUEUE"
    [ "$output" -eq 1 ]
}

# --- list -----------------------------------------------------------------

@test "list shows only open rows" {
    pq add 10.1111/open-one "first"
    pq add 10.2222/soon-done "second"
    pq "done" 10.2222/soon-done

    pq list
    [ "$status" -eq 0 ]
    [[ "$output" == *"10.1111/open-one"* ]]
    [[ "$output" != *"10.2222/soon-done"* ]]
}

@test "list keeps the note attached to its own row when the host is empty" {
    pq add 10.1234/abc "needs full text"
    pq list
    # An empty host column must not shift the note into the host's place.
    [[ "$output" == *"10.1234/abc  — needs full text"* ]]
    [[ "$output" != *"[needs full text]"* ]]
}

@test "list says so when nothing is open" {
    pq add 10.1234/abc
    pq "done" 10.1234/abc
    pq list
    [ "$status" -eq 0 ]
    [[ "$output" == *"no open requests"* ]]
}

# --- done -----------------------------------------------------------------

@test "done flips the status to fulfilled" {
    pq add 10.1234/abc "note"
    pq "done" 10.1234/abc
    [ "$status" -eq 0 ]
    [[ "$output" == *"fulfilled: 10.1234/abc"* ]]

    run grep -ac $'\tfulfilled\t10.1234/abc\t' "$PAPER_QUEUE"
    [ "$output" -eq 1 ]
    run grep -ac $'\topen\t' "$PAPER_QUEUE"
    [ "$output" -eq 0 ]
}

@test "done preserves the other rows and the header" {
    pq add 10.1111/one
    pq add 10.2222/two
    pq "done" 10.1111/one

    run wc -l < "$PAPER_QUEUE"
    [ "$output" -eq 3 ]
    run head -1 "$PAPER_QUEUE"
    [ "$output" = "$(printf 'date\tstatus\tidentifier\thost\tnote')" ]
    run grep -ac $'\topen\t10.2222/two\t' "$PAPER_QUEUE"
    [ "$output" -eq 1 ]
}

@test "done on an unknown identifier is a no-op with a message" {
    pq add 10.1111/one
    pq "done" 10.9999/never-queued
    [ "$status" -eq 0 ]
    [[ "$output" == *"not queued: 10.9999/never-queued"* ]]

    run grep -ac $'\topen\t10.1111/one\t' "$PAPER_QUEUE"
    [ "$output" -eq 1 ]
}

@test "done on a missing queue file is a no-op with a message" {
    pq "done" 10.1234/abc
    [ "$status" -eq 0 ]
    [[ "$output" == *"not queued:"* ]]
    [ ! -f "$PAPER_QUEUE" ]
}

@test "done rejects a call with no identifier" {
    pq "done"
    [ "$status" -eq 1 ]
    [[ "$output" == *"needs an identifier"* ]]
}

# --- status ---------------------------------------------------------------

@test "status counts open and fulfilled separately" {
    pq add 10.1111/one
    pq add 10.2222/two
    pq add 10.3333/three
    pq "done" 10.2222/two

    pq status
    [ "$status" -eq 0 ]
    [[ "$output" == *"open: 2"* ]]
    [[ "$output" == *"fulfilled: 1"* ]]
}

@test "status reports zero counts on an empty queue" {
    pq add 10.1111/one
    pq "done" 10.1111/one
    pq status
    [[ "$output" == *"open: 0"* ]]
    [[ "$output" == *"fulfilled: 1"* ]]
}

@test "status detects a file dropped in for an open request" {
    pq add 10.1234/abc "needs full text"

    pq status
    [[ "$output" != *"files present"* ]]

    # The human fetched it on the host and dropped it next to the queue.
    touch "$PAPERS/10.1234-abc.pdf"

    pq status
    [ "$status" -eq 0 ]
    [[ "$output" == *"files present for open requests:"* ]]
    [[ "$output" == *"10.1234/abc"*"10.1234-abc.pdf"* ]]
}

@test "status slugifies a URL identifier before looking for the file" {
    pq add 'https://www.sciencedirect.com/science/article/pii/X1'
    touch "$PAPERS/www.sciencedirect.com-science-article-pii-x1.pdf"

    pq status
    [[ "$output" == *"files present for open requests:"* ]]
}

@test "status does not count the queue file itself as a dropped-in paper" {
    pq add requests
    pq status
    [[ "$output" != *"files present"* ]]
}

@test "status does not report a file for an already fulfilled request" {
    pq add 10.1234/abc
    touch "$PAPERS/10.1234-abc.pdf"
    pq "done" 10.1234/abc

    pq status
    [[ "$output" == *"fulfilled: 1"* ]]
    [[ "$output" != *"files present"* ]]
}

# --- dispatch -------------------------------------------------------------

@test "an unknown subcommand prints usage and exits non-zero" {
    pq wat
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"paper-queue.sh add"* ]]
}

@test "no subcommand prints usage and exits non-zero" {
    pq
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}
