# API changelog: orders v2 → v3

## Breaking

- Removed required field `customer_id` from `CreateOrder` (`#/components/schemas/CreateOrder/properties/customer_id`)

## Non-breaking

- New optional field `nickname` on `Customer` (`#/components/schemas/Customer/properties/nickname`)
