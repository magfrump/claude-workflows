import type { Request, Response } from "express";

const WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"] as const;
type Weekday = (typeof WEEKDAYS)[number];

interface Shift {
  day: Weekday;
  startHour: number; // 0-23
  endHour: number; // 1-24
}

const MAX_SHIFTS = 21;

// PUT /api/stores/:id/opening-hours
export function updateOpeningHours(req: Request, res: Response) {
  const shifts: Shift[] = req.body.shifts;
  if (!Array.isArray(shifts) || shifts.length > MAX_SHIFTS) {
    return res.status(400).json({ error: `at most ${MAX_SHIFTS} shifts` });
  }

  const byDay = WEEKDAYS.map((day) =>
    shifts
      .filter((s) => s.day === day)
      .sort((a, b) => a.startHour - b.startHour),
  );

  for (const dayShifts of byDay) {
    for (let i = 0; i < dayShifts.length; i++) {
      for (let j = i + 1; j < dayShifts.length; j++) {
        if (dayShifts[j].startHour < dayShifts[i].endHour) {
          return res.status(400).json({ error: "overlapping shifts" });
        }
      }
    }
  }

  const summary = WEEKDAYS.map((day, i) => ({
    day,
    openHours: byDay[i].reduce((h, s) => h + (s.endHour - s.startHour), 0),
  }));

  res.json({ storeId: req.params.id, summary });
}
