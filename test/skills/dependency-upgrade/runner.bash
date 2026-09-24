# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# Dependency upgrade evaluation: the upgrade request (manifest entry, every
# call site, full release notes) goes inline in the prompt. No Read, because
# inline mode runs claude in the real repo, where Read could reach
# expected-verdicts.bash; no Write, so the evaluation goes to stdout (SKILL.md
# presents it in chat anyway).
#
# SKILL.md steps the harness cannot support: web search for the changelog, a
# codebase search for usage, and the Execution evidence protocol's commands
# (audit, install, test, rollback rehearsal). The packages are invented, so a
# web search would find nothing, and nothing can be executed. The prompt says
# plainly that the changelog and usage are complete and that there is no
# repository, shell or web access, and gives the model no tools at all. It
# does not say how to report the evidence it cannot gather: that is what the
# Audit state / rehearsal / evidence-row checks test.
FIXTURE_TOOLS="none"
FIXTURE_MODE="inline"

fixture_prompt() {
  printf '%s' "Evaluate the dependency upgrade described below. The request is self-contained: it gives the manifest entry, every place the project uses the package, and the complete release notes for every version between the current and target versions. You have no repository, shell or web access, so nothing can be searched, installed, audited, tested or otherwise executed. Print the evaluation to stdout; do not write it to docs/working/. The upgrade request:"
}
