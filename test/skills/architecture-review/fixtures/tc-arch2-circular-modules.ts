// Storefront backend — two feature modules, concatenated into one file for review.
//
// Modules:
//   src/customers/  customer records and account standing
//   src/billing/    invoices and payments
//
// Each "// ==== file: <path> ====" marker starts a separate module. Each module
// exposes its public API through its index.ts.

// ==== file: src/customers/customer.ts ====
import { outstandingBalanceCents } from "../billing";

export interface Customer {
  id: string;
  email: string;
  creditLimitCents: number;
  suspended: boolean;
}

const customers = new Map<string, Customer>();

export function getCustomer(id: string): Customer {
  const c = customers.get(id);
  if (!c) throw new Error(`unknown customer ${id}`);
  return c;
}

export function saveCustomer(c: Customer): void {
  customers.set(c.id, c);
}

export function canPlaceOrder(customerId: string, orderCents: number): boolean {
  const c = getCustomer(customerId);
  if (c.suspended) return false;
  return outstandingBalanceCents(customerId) + orderCents <= c.creditLimitCents;
}

// ==== file: src/customers/index.ts ====
export { Customer, getCustomer, saveCustomer, canPlaceOrder } from "./customer";

// ==== file: src/billing/invoice.ts ====
import { getCustomer } from "../customers";

export interface Invoice {
  id: string;
  customerId: string;
  amountCents: number;
  paid: boolean;
  billingEmail: string;
}

const invoices: Invoice[] = [];

export function issueInvoice(customerId: string, amountCents: number): Invoice {
  const customer = getCustomer(customerId);
  const invoice: Invoice = {
    id: `inv_${invoices.length + 1}`,
    customerId,
    amountCents,
    paid: false,
    billingEmail: customer.email,
  };
  invoices.push(invoice);
  return invoice;
}

export function outstandingBalanceCents(customerId: string): number {
  return invoices
    .filter((i) => i.customerId === customerId && !i.paid)
    .reduce((sum, i) => sum + i.amountCents, 0);
}

export function markPaid(invoiceId: string): void {
  const invoice = invoices.find((i) => i.id === invoiceId);
  if (invoice) invoice.paid = true;
}

// ==== file: src/billing/index.ts ====
export { Invoice, issueInvoice, outstandingBalanceCents, markPaid } from "./invoice";

// ==== file: src/checkout/placeOrder.ts ====
import { canPlaceOrder } from "../customers";
import { issueInvoice } from "../billing";

export function placeOrder(customerId: string, amountCents: number) {
  if (!canPlaceOrder(customerId, amountCents)) {
    throw new Error("order exceeds credit limit or account suspended");
  }
  return issueInvoice(customerId, amountCents);
}
