# Predictive Scheduling for Primary Care

**Prepared by:** Clinical Operations Analytics, Brackenridge Community Health
**For:** Executive Committee and Medical Staff Council

## Summary

Missed appointments cost our eleven primary care clinics an estimated 31,000 unused visit slots last year. We propose to use a no-show prediction model, built and validated on our own scheduling data, to double-book the slots most likely to go unused. We expect to recover about 9,000 visits a year without adding clinicians or extending hours, which would shorten the wait for a new-patient appointment from 26 days to about 18.

## Background

Our no-show rate across primary care is 17 percent, above the regional benchmark. Each unused slot is a patient who could have been seen and was not, and a clinician's time that is paid for but idle. Front-desk staff already overbook informally, relying on their own sense of which patients tend not to come, but the practice varies between clinics and between staff members, and nobody tracks whether it works.

## The model

The analytics team trained a gradient-boosted model on 410,000 scheduled appointments from the last three years. For each upcoming appointment it produces a probability that the patient will not arrive. The inputs are:

- the patient's number of missed appointments in the past two years;
- the number of days between booking and the appointment;
- the distance from the patient's home address to the clinic;
- the patient's insurance category (commercial, public, or self-pay);
- the patient's age band;
- the day of week and time of day of the appointment.

On a held-out year of data the model reached an area under the curve of 0.81, well above the informal front-desk judgment it replaces, which we estimated at about 0.62 by comparing overbooking decisions to outcomes. Prior missed appointments, insurance category, and distance were the three most influential inputs.

## How it will be used

Each evening the scheduling system scores the next day's appointments. Any slot where the predicted no-show probability exceeds 40 percent is opened for a second booking. Schedulers fill these slots from the same-day request list and the waitlist.

When both patients arrive, the clinic sees both. In practice this means the second patient, or sometimes the first, waits longer, and on busy days one of them may be asked to return for a shorter follow-up visit later in the week. Clinicians told us in the design sessions that they can absorb one double-booked arrival per half-day session without running late; the threshold was tuned so that, on average, no session has more than one.

## Expected results

In a retrospective simulation over last year's schedule, the policy would have filled 9,200 slots that went unused, while producing a double arrival in about 2,100 of them. Average patient waiting-room time in double-booked sessions would rise by an estimated 11 minutes. Clinic-level productivity would rise by about 7 percent.

## Governance

The model will be retrained quarterly. The analytics team will report the no-show rate, the fill rate of double-booked slots and average wait times to the Executive Committee monthly. Clinicians retain the ability to decline a double booking in their own session.

## Rollout

We propose to begin at the three clinics with the highest no-show rates, which are also our busiest clinics, in the first quarter, and extend to all eleven clinics by midyear.

## Decision requested

Approve the use of the no-show model for scheduling at the three initial clinics, and the analytics team's plan for monthly reporting.
