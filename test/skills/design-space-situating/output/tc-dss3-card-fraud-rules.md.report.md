# Situating Record: Card-not-present fraud screening for Pellam Pay

**Date:** 2026-11-20

## Decision under situating

> Pellam Pay is choosing how to build the rule set that screens card-not-present payments for its 2,400 online merchants. Options: (a) a hand-written rules engine of about 180 rules, (b) a vendor's pre-built rule pack configured to our thresholds, or (c) a gradient-boosted scoring model trained on the last twelve months of labelled chargebacks.

## Situating paragraph

The brief frames this as a choice of static artifact: build it, back-test it, hand it over, and run it as-is. The environment it describes, though, is an ongoing process. The attack mix has turned over three times in twelve months, each wave reached the labels about six weeks late, and two unattacked products launch in the same quarter as the scheme deadline. The most load-bearing dimension is **orientation in time (#2)**. Every criterion is backward-looking and snapshot-shaped, and none of them measures how quickly the screen adapts to the next attack wave. Two other dimensions are close behind. **Reversibility (#5)** has a cliff at handover: after that, nobody can change anything. **Authority (#1)** has no post-launch owner, because risk engineering leaves and operations cannot edit. Read together, this is less "which of three engines" and more "who owns adaptation after week six, and with what budget." The three options mostly differ in where they put that ownership. In (a) it sits with nobody. In (b) it may sit with the vendor if the pack is updated. In (c) it sits with a retraining loop that has no funding. None of the four criteria tests this.

## Dimensional placements

| # | Dimension | Placement | Rationale |
|---|---|---|---|
| 1 | Locus of authority | Centralized during build; **unowned** after handover (option (b) may move authority to the vendor) | Four risk engineers hold all the design authority for six weeks, then leave. Operations can run the artifact but cannot change it, so nobody holds authority over its evolution. |
| 2 | Orientation in time | Forward (fit today's data) + **Snapshot**, set against an environment that is clearly **Process** | "Fit the fraud we see today" plus a back-test on twelve months that contain three different regimes optimizes for attacks that have already rotated out. The handover plan assumes the artifact is finished. |
| 3 | Search / Compose / Emerge | Mixed: (a) Compose, (b) Search (configure from a catalog), (c) Emerge (learned from labels) | The navigation mode differs by option, but in every option the adversary is the party doing the emerging. That matters more than how the initial artifact is authored. |
| 4 | Modeling target | Framed as Structure (the rule set); real pressure is **Context** (adversary, scheme deadline) and Receiver (merchants via false declines and explanations) | The criteria cover structure (catch rate) and receiver (false declines, explainability). Fit with an adversarial, shifting context is delegated to nobody. |
| 5 | Reversibility | Cheap during the build; **cliff at handover**; compliance cliff at end of next quarter | Before handover any rule or model is cheap to change. After it, changes need engineers who have moved to onboarding. So even a known-wrong rule becomes expensive to fix just as the BNPL and gift-card launches and the 0.5% deadline arrive. |
| 6 | Formality | (a) Explicit, (b) Explicit (vendor-configured), (c) Formal/computable but opaque | All three exceed operations' budget for *changing* the artifact, which is zero. The formality question is really about the maintainer, and the plan has no maintainer. |
| 7 | Social structure | Expert-led | Appropriate for the build. Merchants are a fast fraud signal, faster than the six-week chargeback lag, but no feedback channel is designed in. That is worth naming, though it is not load-bearing. |
| 8 | Legibility | Stakeholder (merchants, CRO, card scheme) + Machine | Criterion 3 targets merchant legibility. Option (c) needs a reason-code translation layer to meet it. Operations needs a separate kind of legibility, knowing when the screen is failing, and no criterion asks for it. |

## Tensions surfaced

- **Snapshot framing vs. process environment.** Three regime changes in twelve months imply roughly one more before or during next quarter. A run-as-is artifact is expected to be partly stale within months of handover.
- **Back-test criterion vs. label lag.** The back-test can only score attacks that have already shown up in chargebacks. Each wave took about six weeks to do that, and none of the twelve-month data covers BNPL or gift cards. Criterion 1 is structurally blind to the risk most likely to break the 0.5% threshold.
- **Deadline timing vs. new products.** The scheme deadline and the launch of two unattacked product types fall in the same quarter. A new attack on those products could run for most of the quarter before any label exists.
- **Authority vs. capability after handover.** "Operations runs it as-is" plus "operations cannot change rules" plus "no re-tuning budget" means the artifact has no owner. This is an implicit default, not a chosen position, and only the CRO can resolve it.
- **Option (c) vs. the no-retraining constraint.** A model trained on labelled history decays fastest without retraining. As framed, its main advantage, learning the mix, is switched off after launch.
- **Option (b)'s hidden variable.** Whether the vendor pack receives vendor-maintained updates after configuration is unstated. If it does, (b) is the only option that quietly reintroduces a post-launch owner. That is a property of the contract, not the rules.
- **Metric mismatch (minor).** The brief quotes 0.41% chargeback *losses* as a share of volume, while the scheme constraint is a *fraud rate*. Confirm these are the same measure before treating the headroom as 0.09 points.
- **Explainability vs. option (c).** Criterion 3 requires per-decline explanations to merchants. Option (c) meets it only with a reason-code layer, which has to fit inside the six-week build.

## Hand-off

This record is a frame, not a decision. It is input to **DD's diagnosis step (step 2)**. There is one prerequisite: the CRO needs to settle the post-launch ownership question, because it is currently a default nobody chose. With that done, the constraints DD can make testable are:

- **Adaptation owner (#1, #5):** name who changes the screen after handover and within what turnaround. If the answer stays "nobody," every candidate carries "stale within one attack cycle" as a named risk.
- **Adaptation criterion (#2):** add a criterion beyond back-test fit. Examples: time to respond to a new pattern, or a holdout back-test that trains on Q1–Q2 and scores Q3 refund abuse, which simulates a regime change.
- **Pre-label signals (#2, #7):** state whether merchant reports, velocity alerts, or other signals can trigger changes faster than the six-week chargeback lag. This matters most for BNPL and gift cards.
- **Vendor update terms (#1, #3):** establish whether option (b) includes ongoing vendor rule updates. This may change its ranking more than anything in the current criteria.
- **Operations' change surface (#6):** decide whether operations can be given a no-code layer, such as thresholds, allow/deny lists, or rule toggles. That would raise their formality budget above zero without needing engineers.

With these explicit, DD's diverge step should expect candidates that combine engines, for example a vendor pack plus operations-editable thresholds, or a model plus a small set of hand rules for new products. It should not assume a single winner among (a), (b), and (c).
