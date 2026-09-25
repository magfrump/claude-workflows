# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# arithmetic-eval is a routing skill: its job is that every figure goes through
# the Mode 1 evaluator instead of mental math. The fixtures measure that routing
# with FIXTURE_BASH=deny-record (Q-063 [1], dd-arith-eval-bash-grant.md): Bash
# is offered, every call is denied, and the eval compares the command the model
# tried with SKILL.md's Mode 1 block (mode1_equiv:). Nothing ever executes.
#
# Inline mode: the draft is in the prompt, so no file tools are needed, and the
# run's directory is empty. The prompt names neither the evaluator nor Bash, so
# a Mode 1 call is the model's own choice. It does not say Bash will be denied;
# what the model does after the denial is graded by separate tests in
# arithmetic-eval-eval.bats.
FIXTURE_TOOLS="Bash"
FIXTURE_MODE="inline"
FIXTURE_TRANSCRIPT=1
FIXTURE_BASH="deny-record"

fixture_prompt() {
  printf '%s' "Check the figures in the draft below: for each number that is derived from other numbers, say whether it is right. This is a non-interactive run; no human will answer questions. The draft:"
}
