import type { Request, Response } from "express";
import { contactsRepo } from "./contactsRepo";

interface Contact {
  email: string;
  name: string;
  phone?: string;
  updatedAt: number;
}

// POST /api/contacts/import
// Body: { contacts: Contact[] } uploaded from a CSV the user exports from
// their CRM.
export async function importContacts(req: Request, res: Response) {
  const incoming: Contact[] = req.body.contacts ?? [];
  const existing: Contact[] = await contactsRepo.listForUser(req.user.id);

  const merged: Contact[] = [...existing];
  let added = 0;
  let updated = 0;

  for (const contact of incoming) {
    const email = contact.email.trim().toLowerCase();
    const idx = merged.findIndex((c) => c.email.toLowerCase() === email);
    if (idx === -1) {
      merged.push({ ...contact, email });
      added++;
    } else if (contact.updatedAt > merged[idx].updatedAt) {
      merged[idx] = { ...merged[idx], ...contact, email };
      updated++;
    }
  }

  await contactsRepo.replaceForUser(req.user.id, merged);
  res.json({ added, updated, total: merged.length });
}
