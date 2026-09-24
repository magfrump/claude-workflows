# Decision brief: automating roast profiles at Fernhollow Coffee

**Decision.** Fernhollow Coffee is choosing how to specify roast profiles for
its new automated drum roaster. The options are (a) a fixed temperature curve
per coffee, (b) a decision table of adjustment rules keyed on bean density and
moisture, or (c) a constraint specification the roaster's controller executes
directly, with operators locked out of manual adjustment during a batch.

**Who is deciding.** Operations director Hanne Vlogt, with the roaster
vendor's integration engineer.

**Context.** Fernhollow roasts 38 single-origin coffees, and the lineup
changes with each harvest. For eleven years every profile has been run by head
roaster Marta Oduya. Marta adjusts gas and airflow mid-batch by the smell of
the beans, the colour through the trier, and the pitch and pace of first
crack. She says she "couldn't write down" why she changes a batch, only that
she knows when it is going wrong. Her two assistants have learned by standing
next to her for two to four years; neither runs a batch alone on a new
harvest. Cupping scores on her batches average 86.5, and wholesale customers
cite consistency as the reason they stay.

**How we are framing it.** Management prefers option (c). A complete, formal
specification means any operator can run any coffee, the controller can prove
each batch stayed within its limits, and we are no longer dependent on one
person. The vendor estimates six weeks for Marta to "write down her rules" into
the specification format with their engineer, after which manual adjustment
will be switched off.

**Criteria.**

1. Batch-to-batch variation in roast colour, measured by the controller.
2. Labour: one operator can supervise two roasters.
3. Controller-verified compliance with each profile's limits.

**Constraints.** The roaster arrives in eight weeks. Marta plans to reduce to
three days a week next spring.
