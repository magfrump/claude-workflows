// Event contracts published to the `orders` topic. Downstream services
// (fulfilment, analytics, notifications) deserialize these payloads.

export interface EventEnvelope<TType extends string, TData> {
  type: TType;
  version: 1;
  event_id: string;
  data: TData;
}

export interface OrderCreatedData {
  order_id: string;
  customer_id: string;
  total_cents: number;
  currency: string;
  occurred_at: string; // ISO-8601 UTC
}

export interface OrderPaidData {
  order_id: string;
  payment_id: string;
  amount_cents: number;
  currency: string;
  occurred_at: string; // ISO-8601 UTC
}

export interface OrderShippedData {
  order_id: string;
  carrier: string;
  tracking_number: string;
  occurred_at: string; // ISO-8601 UTC
}

export type OrderCreated = EventEnvelope<"order.created", OrderCreatedData>;
export type OrderPaid = EventEnvelope<"order.paid", OrderPaidData>;
export type OrderShipped = EventEnvelope<"order.shipped", OrderShippedData>;

// BEGIN CHANGE UNDER REVIEW
export interface OrderCancelledData {
  order_id: string;
  reason: string;
  cancelled_by: string;
  timestamp: number; // epoch milliseconds
}

export type OrderCancelled = EventEnvelope<"order.cancelled", OrderCancelledData>;
// END CHANGE UNDER REVIEW

export type OrderEvent = OrderCreated | OrderPaid | OrderShipped | OrderCancelled;

export function makeEnvelope<TType extends string, TData>(
  type: TType,
  eventId: string,
  data: TData,
): EventEnvelope<TType, TData> {
  return { type, version: 1, event_id: eventId, data };
}
