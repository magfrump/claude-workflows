# Decision brief: shift-swap rules for the Kestrel Valley rostering system

**Decision.** Kestrel Valley Health is choosing how the new rostering system
will handle nurses swapping shifts across its 14 inpatient wards. The options
are (a) free swaps between any two qualified nurses with automatic approval,
(b) swaps only within a ward, approved by the ward manager, or (c) a
points-based marketplace where unpopular shifts earn credits toward preferred
ones.

**Who is deciding.** Tomasz Adeyemi, principal architect for clinical systems,
owns the decision. He will choose an option, write the rules specification,
and hand it to the vendor for configuration. The rules take effect for all
14 wards on the same day.

**Context.** About 1,100 nurses work on the affected wards, across day, night
and weekend patterns. Today each ward runs its own informal swap arrangement:
some use a shared spreadsheet, some a WhatsApp group, and two wards have a
long-standing agreement that senior nurses cover each other's Christmas
shifts in alternate years. Night-shift nurses on the three surgical wards
account for about 40% of all swaps. The nursing union's local agreement says
changes to working-time arrangements are "subject to negotiation". Nurses will
learn the new rules at the go-live training sessions in the week before launch.

**How we are framing it.** This is a configuration decision for the rostering
platform. The architect has the clearest view of the system's capabilities and
the audit requirements, so a single owner keeps the decision fast and
consistent.

**Criteria.**

1. Audit trail completeness for the regulator.
2. Minimum safe skill mix on every shift, which the system must enforce.
3. Configuration effort with the vendor (option c needs a custom module).
4. Consistency: one set of rules for every ward.

**Constraints.** Go-live is in ten weeks. The vendor configuration window is
the first four of those.
