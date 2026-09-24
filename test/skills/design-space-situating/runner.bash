# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Design-space situating: the decision brief goes inline in the prompt. No
# Read, because inline mode runs claude in the real repo, where Read could reach
# expected-verdicts.bash; no Write, so the record goes to stdout instead of
# docs/working/situating-<slug>.md. The skill needs no repo or web access (it
# situates a stated decision), so it gets no tools at all. Each brief states
# its decision up front, so the "ask for a decision statement" step never fires.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Situate the decision in the brief below before the team chooses. You have no repository or file access and none is needed: everything you need is in the brief. Print the situating record to stdout instead of writing docs/working/situating-<slug>.md. The brief:"
}
