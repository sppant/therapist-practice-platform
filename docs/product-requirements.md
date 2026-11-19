# Product Requirements

Status: draft v1 (Phase 1). Source: master specification given by the user in-session. Anything marked **Assumption** or listed under Open Questions is not a decision. Technical design is out of scope here and belongs to the Software Architect (flagged as `[ARCH]`).

Repo state at time of writing: **Verified** no application code; `docs/` contained only `project-progress.md`; `README.md` and `CLAUDE.md` read and not contradicted.

## 1. Product summary and goals

A scheduling and practice-management platform for independent therapists and small practices. Therapists publish a profile and public booking page, define availability, and manage appointments and clients. Clients (guests, no account) discover therapists, pick a slot, and book in under two minutes; they manage that one booking through a secure link. A small platform-admin area manages accounts.

Positioning: trust, privacy, calm, professionalism, simplicity. It is scheduling only.

Goals
- G1: Zero double bookings, ever (enforced independent of the UI).
- G2: A guest can complete a booking in at most 6 steps with no account.
- G3: Times are always correct in the therapist's zone and shown in the client's zone, including across DST.
- G4: Collect the minimum personal data needed to schedule and communicate.
- G5: Look and feel like a premium commercial product (see design docs, written separately).

Success measures (MVP, internal): all critical-flow acceptance criteria (section 9) pass in automated tests; no cross-tenant access in security tests; WCAG 2.2 AA checks pass on the booking flow.

## 2. Personas

| Persona | Description | Key needs |
|---|---|---|
| Therapist (Maya, solo practitioner) | Independent, not technical, works part-time, different hours per weekday | Fast setup, no double bookings, fewer no-shows, privacy for clients, minimal admin |
| Practice owner | Runs a small practice | Practice details on the page. **Assumption:** MVP = one therapist per account (see OQ-01) |
| Client (Sam, guest) | First-time client, possibly anxious about privacy, mobile, maybe in another time zone | Find the right therapist, clear times in own zone, no account, no health questions, easy cancel |
| Platform administrator | Operator of the platform | See accounts, disable abusive ones, basic stats; no access to client details |

## 3. Scope

### Must have (MVP)
Therapist auth and account settings; profile and public page; session types; weekly hours, date blocks, breaks, buffers, notice, advance window; slot computation; guest booking; token links (view, cancel, reschedule); therapist appointment management; client list; calendar day/week/month with create/reschedule/cancel; dashboard; discovery with search/filters/pagination; emails (confirmation, cancellation, rescheduling, reminders) with reliable processing; platform admin (list, disable/reactivate, stats); public pages (home, discovery, profile, booking, login, register, privacy, terms); GDPR-supporting features (export, deletion, retention); rate limiting and brute-force protection; accessibility and responsive behaviour; demo data clearly labelled.

### Should have
Email verification at registration; password reset; therapist-side reminder preferences (client reminder lead time); ICS attachment/link in confirmation email; client "add to calendar"; no-show marking; client list CSV export; admin audit log; session-type-specific meeting instructions text.

### Later
Multi-staff practices and per-staff calendars; waitlist; recurring appointments (series); two-factor auth; booking approval mode; SMS reminders; calendar sync (Google/Outlook); localization (additional UI languages); custom domains; payments (explicitly a later non-goal for MVP).

### Explicit non-goals (MVP)
Payments and subscription billing; video conferencing; clinical records, diagnoses, therapy notes, medical histories; AI therapy recommendations; insurance integrations; client accounts/logins; reviews/ratings; messaging/chat; free-text "reason for visit" or any health information fields.

Decision explained: the booking form asks only name, email, optional phone, time zone (auto-detected, editable) and consent. It deliberately has no reason-for-visit or free-text field. Reasons: data minimization, avoids special-category (health) data under GDPR Art. 9, reduces breach impact, and matches the product's scheduling-only positioning. Therapists collect clinical context in session, outside the platform.

## 4. Functional requirements

Priority: M = must, S = should. IDs are stable; tests and tasks trace to them.

### 4.1 Authentication and accounts (AUTH)
- REQ-AUTH-001 (M) Therapist can register with email and password, accept Terms and Privacy Policy, and set an IANA time zone (default detected from browser, editable).
- REQ-AUTH-002 (M) Password policy: minimum 12 characters, checked against a common-password list **Assumption** (exact policy `[ARCH]`); no composition rules beyond length.
- REQ-AUTH-003 (M) Login with email and password; generic error message that does not reveal whether the email exists.
- REQ-AUTH-004 (M) Brute-force protection: progressive throttling or temporary lockout per account and per IP; lockout message does not reveal account existence; legitimate owner gets recovery path (password reset, S).
- REQ-AUTH-005 (M) Logout invalidates the session/credential server-side `[ARCH]`.
- REQ-AUTH-006 (M) Change password requires current password; other sessions are invalidated.
- REQ-AUTH-007 (S) Email verification before the profile can be published; password reset via emailed single-use expiring link.
- REQ-AUTH-008 (M) Roles: THERAPIST, ADMIN. Guests are unauthenticated. Every protected endpoint enforces role server-side.
- REQ-AUTH-009 (M) A disabled therapist cannot log in; the message states the account is disabled and how to contact support.
- REQ-AUTH-010 (M) Account deletion by the therapist (see sections 6.5 and 7).

### 4.2 Therapist profile and public page (PROF)
- REQ-PROF-001 (M) Therapist edits: display name, professional title, photo, biography, specializations (from a platform-managed list plus limited free tags **Assumption**), languages, location (city/country and optional address), practice details (practice name, contact email, phone, website), introduction text.
- REQ-PROF-002 (M) Session types: name, duration (minutes), mode (online / in-person / both as separate types), optional short description, active flag. No price field. At least one active session type is required to publish.
- REQ-PROF-003 (M) Public booking page at a stable human-readable slug (unique, validated, reserved words blocked); slug change keeps working redirect from the old slug for a period `[ARCH]`/OQ-12.
- REQ-PROF-004 (M) Publish/unpublish toggle. Unpublished profiles are not discoverable and cannot be booked; their URL shows a neutral "not available" page.
- REQ-PROF-005 (M) Photo upload: type and size limits, server-side validation, no EXIF location leakage `[ARCH]`; initials placeholder if none.
- REQ-PROF-006 (M) Profile text is plain text or restricted formatting; output is escaped; no raw HTML.
- REQ-PROF-007 (M) Field limits (display name 100, bio 3000, etc.) with UI truncation rules for long values (see edge cases).
- REQ-PROF-008 (M) Credentials are free text written by the therapist; the platform does not verify them and the profile footer states "Credentials are provided by the therapist and not verified by the platform". Demo profiles are flagged "Demo content".

### 4.3 Availability (AVAIL)
- REQ-AVAIL-001 (M) Weekly working hours: for each weekday, zero or more time ranges (local time of the therapist's zone), e.g. Mon 09:00-12:00 and 14:00-18:00.
- REQ-AVAIL-002 (M) Breaks: recurring (weekly, per weekday) breaks within working hours that remove bookable time.
- REQ-AVAIL-003 (M) Date blocks: block a whole date or a time range on a specific date or date range (holiday, vacation); optional private label never shown to clients.
- REQ-AVAIL-004 (S) Date-specific extra hours (override) for a single date.
- REQ-AVAIL-005 (M) Appointment duration comes from session type; buffer time (minutes, 0-60 **Assumption**) after each appointment; minimum booking notice (hours); maximum advance booking period (days); slot start interval (see OQ-03).
- REQ-AVAIL-006 (M) Therapist time zone can be changed in settings. Existing appointments keep their absolute UTC instant; weekly hours are reinterpreted in the new zone. UI shows a warning with the count of future appointments affected and states that appointment instants do not move (see OQ-07).
- REQ-AVAIL-007 (M) Changing availability never auto-cancels existing appointments. If a change conflicts with future confirmed appointments, the UI lists them and requires explicit acknowledgement; the therapist handles each manually.
- REQ-AVAIL-008 (M) The slot list is computed by the backend using the rules in section 6; the frontend never computes availability itself.
- REQ-AVAIL-009 (M) Therapist can view a "preview as client" of next bookable slots.

### 4.4 Public discovery (DISC)
- REQ-DISC-001 (M) Discovery lists only published, active (not disabled), onboarding-complete therapists.
- REQ-DISC-002 (M) Free-text search (name, specialization, location); filters: specialization, location, language, mode (online / in-person); combinable; paginated (default 12 per page); stable ordering `[ARCH]` (recommended default: random-but-stable daily seed is later; MVP = alphabetical by display name, no paid placement, no ranking claims).
- REQ-DISC-003 (M) Result card: photo, name, title, specializations, languages, location, modes, next available slot (optional S), link to profile.
- REQ-DISC-004 (M) Empty results state with a "clear filters" action; filter state reflected in the URL (shareable); pages SSR-rendered for SEO.
- REQ-DISC-005 (M) Profile page shows photo, name, bio, specializations, languages, location, session types with durations, introduction, availability preview, book CTA, credentials disclaimer.
- REQ-DISC-006 (M) Public responses never expose therapist email/phone unless the therapist opted to show them (default hidden, booking is the contact path) **Assumption**.

### 4.5 Guest booking (BOOK)
- REQ-BOOK-001 (M) Flow: open profile -> choose session type -> choose date -> see slots -> choose time -> enter contact details -> review and confirm -> confirmation screen and email.
- REQ-BOOK-002 (M) Dates and slots are shown in the client's selected time zone (default browser zone) with the zone name visible and a switcher; the therapist's zone is also shown ("Therapist time: 10:00 Europe/Berlin").
- REQ-BOOK-003 (M) Contact details: full name (required), email (required, validated, confirmed by display), phone (optional), consent checkbox to Privacy Policy and Terms (required, unticked by default). No other personal fields.
- REQ-BOOK-004 (M) On submit the backend re-validates the slot against current availability, notice, advance window, session type active, therapist active, and overlap, independent of what the client saw.
- REQ-BOOK-005 (M) Concurrent attempts for the same slot (or overlapping slots): exactly one succeeds; the others get a clear "slot no longer available" response with refreshed alternatives (HTTP-level detail `[ARCH]`).
- REQ-BOOK-006 (M) Idempotent submission: a client-generated idempotency key makes repeated submissions (double click, retry, network replay) return the same appointment and send one email. Key scope and TTL `[ARCH]`.
- REQ-BOOK-007 (M) Slot hold: while the client fills the form, no hold is guaranteed in MVP (**Assumption**, OQ-04); the final submit is authoritative.
- REQ-BOOK-008 (M) Booking is auto-confirmed (no therapist approval) by default.
- REQ-BOOK-009 (M) Confirmation screen shows therapist, session type, date/time in the client's zone and the therapist's zone, location or online instructions, cancellation policy in plain language, and a link to manage the booking.
- REQ-BOOK-010 (M) Abuse controls: rate limit per IP and per email; limit of N upcoming confirmed bookings per email per therapist (default 3 **Assumption**, OQ-09); optional bot challenge (OQ-10).
- REQ-BOOK-011 (M) Booking the same email repeatedly never reveals whether the email belongs to an existing client of that therapist.
- REQ-BOOK-012 (M) Client's name, email and time zone are stored as a per-therapist client record (tenant-scoped); there is no cross-tenant client identity.

### 4.6 Secure token access (TOKEN)
- REQ-TOKEN-001 (M) Each appointment has a management token delivered only in the confirmation email and on the confirmation screen; the URL contains no sequential ID.
- REQ-TOKEN-002 (M) A token grants access to exactly one appointment, never to other appointments of the same client, and never to any therapist-side data.
- REQ-TOKEN-003 (M) Tokens are unguessable (cryptographically random, at least 128 bits of entropy); stored so that a database leak does not reveal valid tokens (`[ARCH]`, recommended: stored hashed).
- REQ-TOKEN-004 (M) Token page shows appointment details and, if the policy allows, cancel and reschedule actions. Invalid, unknown, or expired tokens return an identical neutral "link not valid" response (no oracle for existence).
- REQ-TOKEN-005 (M) Token validity: view access until a retention horizon after the appointment (default: appointment end + 30 days **Assumption**, OQ-08); cancel/reschedule only before the appointment start and within policy.
- REQ-TOKEN-006 (M) Token endpoints are rate limited and send `no-referrer`, `noindex`, no-cache headers; tokens must not be logged or sent to third parties (analytics, referrers).
- REQ-TOKEN-007 (S) "Resend my link" by email returns a generic response and sends the link only if matching upcoming appointments exist.

### 4.7 Cancellation and rescheduling (CANC)
- REQ-CANC-001 (M) Therapist configures a cancellation policy: free-cancellation window in hours before start (0 = anytime until start; default 24h). Same policy governs client reschedule.
- REQ-CANC-002 (M) Client cancel via token: allowed if now is at or before (start minus window) and the appointment is CONFIRMED. Otherwise the page explains the policy and shows therapist contact details (the therapist's contact email is shown here even if hidden publicly). No fees (no payments).
- REQ-CANC-003 (M) Therapist can cancel any future confirmed appointment at any time, with an optional message to the client included in the email (plain text, length-limited; therapist is warned not to include health info).
- REQ-CANC-004 (M) Cancelling frees the slot immediately for new bookings, sends cancellation emails, stops pending reminders.
- REQ-CANC-005 (M) Cancel is idempotent: repeated cancel requests succeed with the same final state and one email.
- REQ-CANC-006 (M) Client reschedule via token: select a new slot (same session type, same therapist) using the same slot rules; allowed under the same window as cancel; the original slot is freed only if the new slot is secured, atomically (never lose both). Same token and appointment identity retained; history records the change.
- REQ-CANC-007 (M) Therapist reschedule: any time before start, to any valid slot, with an option to override availability rules (outside hours/notice) while still never overlapping another confirmed appointment (OQ-05). Client is emailed.
- REQ-CANC-008 (M) Reschedule is idempotent (idempotency key) and concurrency-safe like booking.
- REQ-CANC-009 (S) Maximum reschedules per appointment (default none) .

### 4.8 Appointments management, therapist (APPT)
- REQ-APPT-001 (M) List with pagination, sort by start time, search (client name/email), filters (status, date range, session type, upcoming/past).
- REQ-APPT-002 (M) Detail view: client contact, session type, times (therapist zone, with client zone shown), status, history of status changes and reschedules, notification delivery status (sent/failed).
- REQ-APPT-003 (M) Therapist can create an appointment for an existing or new client (same overlap validation; optional "send confirmation email").
- REQ-APPT-004 (M) Status actions per the lifecycle (section 7): cancel, reschedule, mark completed, mark no-show.
- REQ-APPT-005 (M) Only the owning therapist can see or modify an appointment (tenant isolation).
- REQ-APPT-006 (M) Past appointments are read-only except status corrections: CONFIRMED -> COMPLETED/NO_SHOW (allowed once start has passed).

### 4.9 Clients (CLIENT)
- REQ-CLIENT-001 (M) Client record fields: name, email, phone (optional), time zone, created date. No free-text notes field and no health data (see OQ-11).
- REQ-CLIENT-002 (M) List with search (name/email), filter (has upcoming appointment, last seen range), pagination.
- REQ-CLIENT-003 (M) Detail: contact info, appointment history, upcoming appointments, quick "book appointment".
- REQ-CLIENT-004 (M) Therapist can edit contact info; email change does not alter tokens of existing appointments but future notifications use the new email.
- REQ-CLIENT-005 (M) Therapist can delete/anonymize a client (see sections 6.5 and 7).
- REQ-CLIENT-006 (M) Clients are unique per therapist by normalized email (case-insensitive); name differences update the display name from the most recent booking only if the therapist has not manually edited it **Assumption**.
- REQ-CLIENT-007 (S) CSV export of client list.

### 4.10 Calendar (CAL)
- REQ-CAL-001 (M) Day, week and month views; today button; previous/next navigation; jump to date; first day of week per locale **Assumption** (default Monday).
- REQ-CAL-002 (M) Calendar is rendered in the therapist's zone; shows appointments with status styling, working hours shading and blocked dates.
- REQ-CAL-003 (M) Click appointment -> details drawer/dialog with actions. Click empty slot -> create appointment prefilled.
- REQ-CAL-004 (M) Reschedule via a date/time picker; drag-and-drop is optional (S) and must have a keyboard-accessible alternative.
- REQ-CAL-005 (M) DST days render the correct number of hours (23/25); non-existent local times are not selectable; repeated local hours are disambiguated with the offset.
- REQ-CAL-006 (M) Keyboard navigable; screen-reader accessible event list alternative (agenda list) for each view.
- REQ-CAL-007 (M) Loading, empty (no appointments) and error states.

### 4.11 Dashboard (DASH)
- REQ-DASH-001 (M) Shows today's appointments, upcoming (next 7 days), total clients, recent activity (bookings, cancellations, reschedules, last 10), quick actions (create appointment, block time, copy booking link, edit availability).
- REQ-DASH-002 (M) Onboarding checklist until publishable (profile, session type, hours, publish).
- REQ-DASH-003 (M) Empty state for new accounts.

### 4.12 Notifications (NOTIF)
- REQ-NOTIF-001 (M) Emails: booking confirmation (client; therapist copy configurable), cancellation (to the other party), reschedule (client; therapist), reminder (client; therapist optional).
- REQ-NOTIF-002 (M) Reminder lead time: default 24 hours before start; therapist can choose 2/24/48h or off (**Assumption**, OQ-06). Reminder is sent only for CONFIRMED future appointments; a reschedule recalculates; cancel removes.
- REQ-NOTIF-003 (M) Background processing is reliable: persisted work queue that survives restarts; at-least-once processing combined with deduplication so a given (appointment, type, version) email is sent at most once from the user's perspective; multi-instance safe `[ARCH]`.
- REQ-NOTIF-004 (M) Retry with exponential backoff on delivery failure, capped attempts (default 5), then marked FAILED and visible to the therapist on the appointment; no endless retry.
- REQ-NOTIF-005 (M) Booking is never blocked or rolled back by email failure; the confirmation screen still shows the details.
- REQ-NOTIF-006 (M) Email content: plain, calm, no health information, no marketing; includes times in the recipient's zone (client zone known) and the therapist's zone; includes the manage link; text and HTML parts; ICS attachment (S).
- REQ-NOTIF-007 (M) Emails carry a transactional footer with the sender identity and a privacy link; no tracking pixels (privacy) **Assumption**.
- REQ-NOTIF-008 (M) Notification preferences for the therapist: which emails they receive; client-facing mandatory emails (confirmation, cancellation, reschedule) cannot be disabled.
- REQ-NOTIF-009 (M) Locally emails go to Mailpit; templates are tested.
- REQ-NOTIF-010 (M) Reminders that become due while the system was down are sent late only if the appointment is more than a minimum lead away (default 1h) **Assumption**; otherwise skipped and logged.

### 4.13 Platform administration (ADMIN)
- REQ-ADMIN-001 (M) Admin lists therapists/practices with name, email, status, created date, last login, counts (appointments, clients) but **no client personal data and no appointment contents**.
- REQ-ADMIN-002 (M) Disable and reactivate an account with a recorded reason; effects in section 6.5.
- REQ-ADMIN-003 (M) Basic stats: registered therapists, active/disabled, published profiles, appointments created in the last 7/30 days, emails failed in the last 7 days.
- REQ-ADMIN-004 (M) Admin accounts are not self-registered (seeded or created out of band `[ARCH]`); admin cannot disable themselves; admin actions are audit-logged.
- REQ-ADMIN-005 (S) Admin can trigger a therapist password reset email; cannot set passwords or impersonate.

### 4.14 Account settings (SET)
- REQ-SET-001 (M) Change password, notification preferences, time zone (REQ-AVAIL-006), cancellation policy, email change (requires re-verification, S), export my data, delete my account.
- REQ-SET-002 (M) Booking link copy/share and slug display.

### 4.15 Public site (PUB)
- REQ-PUB-001 (M) Pages: home (hero, value proposition, how it works, therapist discovery teaser, platform benefits, CTAs, footer), discovery, profile, booking flow, login, registration, privacy policy, terms of service.
- REQ-PUB-002 (M) Privacy policy and terms are drafted as clearly marked **template drafts that must be reviewed by a qualified professional before real use**; no claim of legal compliance.
- REQ-PUB-003 (M) Seeded demo therapists/clients are fictional, labelled "Demo", use reserved domains (example.com) and no real people's photos or qualifications; the home page makes no claims of user counts or testimonials that do not exist.
- REQ-PUB-004 (M) Public pages have titles, meta descriptions, canonical URLs; token and account pages are `noindex`.
- REQ-PUB-005 (M) Cookie/consent: only strictly necessary storage in MVP, so no consent banner is required; if analytics are ever added, consent is required first **Assumption**.

## 5. Non-functional requirements

- REQ-NFR-001 Accessibility: WCAG 2.2 AA where practical; full keyboard flow for booking and calendar; visible focus; contrast; labels and error association; live-region announcements for slot loading/errors; target size at least 24x24 CSS px; no information by colour alone.
- REQ-NFR-002 Responsive: designed mobile-first; supports 360px to desktop; calendar degrades to agenda view on narrow screens.
- REQ-NFR-003 Reduced motion: respect `prefers-reduced-motion`; no essential information conveyed by animation.
- REQ-NFR-004 Every screen defines loading, empty, error (and offline/timeout where relevant) states.
- REQ-NFR-005 Performance targets (**Assumption**, to be validated): slot query p95 < 500 ms for a 31-day window at demo scale; public pages SSR with LCP < 2.5 s on a mid-range mobile profile.
- REQ-NFR-006 Security baseline: OWASP ASVS-oriented; role checks server-side; input validation at the API; output encoding; secure headers; CSRF protection appropriate to the auth mechanism `[ARCH]`; secrets never in repo or logs.
- REQ-NFR-007 Tenant isolation: tenant derived from the authenticated principal, never from client-supplied IDs; any cross-tenant read/write is a critical defect; tested for every therapist-owned resource.
- REQ-NFR-008 Time: stored as UTC instants plus explicit zone ids; no implicit server zone; API uses ISO-8601 with offset/Z plus zone id where local semantics matter.
- REQ-NFR-009 Reliability: double booking prevented at the database level; background jobs survive restart; migrations versioned.
- REQ-NFR-010 Observability: structured logs with correlation ids; no personal data or tokens in logs; health endpoint.
- REQ-NFR-011 Maintainability: API contract first (OpenAPI); consistent error format `[ARCH]`.
- REQ-NFR-012 Browser support: current and previous major versions of evergreen browsers **Assumption**.
- REQ-NFR-013 Internationalisation readiness: UI strings externalised; English only in MVP; date/time formatting uses the client's locale **Assumption**.
- REQ-NFR-014 Rate limiting: applied to login, registration, password reset, booking, token endpoints, discovery; responses indicate retry time.

## 6. Business rules

### 6.1 Time
- BR-TIME-001 Availability is evaluated in the therapist's IANA zone; results are converted to UTC instants.
- BR-TIME-002 Spring-forward gap: local times that do not exist (e.g. 02:30 on the transition date) are never offered. A working-hours range spanning the gap produces slots only for existing local times, and total slot time is reduced accordingly. A slot whose duration would straddle the gap is computed on elapsed (real) time, not wall-clock time.
- BR-TIME-003 Fall-back repetition: local times occurring twice are offered as two distinct instants (both occurrences) if the working-hours range covers them, each labelled with its offset in UI where ambiguous. **Assumption** (alternative: offer only the first occurrence; see OQ-13).
- BR-TIME-004 Appointment duration is elapsed real time (e.g. 60 minutes), not wall-clock difference.
- BR-TIME-005 A working range ending at or crossing midnight is not supported in MVP: ranges are within a single local day (**Assumption**, OQ-14).
- BR-TIME-006 "Day" for date selection by the client is the therapist's local date; the client display converts each slot to the client's zone, and a slot may appear on a different calendar day for the client. The date picker shows the therapist's dates and each slot shows the client's local date/time when different.
- BR-TIME-007 Zones with unusual offsets (e.g. 30/45-minute offsets) and zones that skipped or changed offset on a date are handled by using the tz database rules; slot grids align to the therapist's local clock.
- BR-TIME-008 Tz database updates must not silently move existing appointments: stored instants are authoritative; local display may change if rules change (documented limitation).

### 6.2 Slot generation
A slot (start instant S, session type with duration D) is bookable if and only if all hold:
1. S's local start falls on the slot grid (OQ-03) within a working range, and S + D is not after the range end (the appointment must end within working hours).
2. [S, S+D) does not intersect a break or date block.
3. The candidate's occupied interval [S, S+D+buffer) does not intersect any CONFIRMED appointment's occupied interval [start, end+buffer). Hence a buffer separates appointments on both sides; the buffer after the last appointment of the day may extend past working hours.
4. S >= now + minimum notice.
5. S <= now + maximum advance period (the cut-off is the end of the therapist-local date that is the maximum advance days from today, **Assumption**).
6. The session type is active; the therapist is active and published.
7. S is in the future.
- BR-SLOT-001 Back-to-back appointments are allowed only when buffer = 0; with a buffer, the next start is at or after previous end + buffer.
- BR-SLOT-002 Different session types with different durations share one calendar; one appointment occupies the therapist exclusively (no parallel clients) in MVP.
- BR-SLOT-003 Intervals are half-open [start, end): an appointment ending 10:00 and another starting 10:00 do not overlap.
- BR-SLOT-004 Zero slots: the UI shows an explicit empty state with the next date that has availability (if within the window) or contact guidance.
- BR-SLOT-005 Only CONFIRMED appointments (and therapist-created confirmed ones) occupy time; cancelled, completed-in-past and no-show do not block future computation (past is irrelevant).

### 6.3 Cancellation policy model
- Per therapist: `freeCancellationHours` (integer, 0-168, default 24). Applies to client cancel and client reschedule.
- The therapist is never restricted. No penalties or fees (non-goal).
- The policy in force at booking time is snapshotted on the appointment, so later policy changes do not retroactively change that appointment's rights **Assumption** (OQ-15).
- The deadline is shown to the client in their zone, including exact time.

### 6.4 Rescheduling rules
- Same therapist, same session type (changing type requires cancel + new booking in MVP).
- Client reschedule validates the new slot with all section 6.2 rules at the time of the request. Therapist reschedule may override hours/notice (OQ-05), never overlap.
- The appointment retains id/token; start/end update; reminders re-planned; one rescheduling email; history entry recorded (old start, new start, actor).
- Rescheduling to the identical time is rejected with a clear message.

### 6.5 Effects of changes on future appointments
| Event | Existing future CONFIRMED appointments |
|---|---|
| Therapist edits hours, breaks, blocks, buffer, notice, advance period | Unchanged (never auto-cancelled); conflicts listed for the therapist |
| Therapist deactivates a session type | Unchanged; type cannot be newly booked |
| Therapist unpublishes profile | Unchanged; token links continue to work; new bookings blocked |
| Therapist time zone change | Instants unchanged; warning shown (REQ-AVAIL-006) |
| Admin disables therapist | Unchanged by default (not auto-cancelled); new bookings blocked; page hidden; therapist cannot log in; reminders suspended; token page shows a notice to contact the therapist (OQ-16) |
| Admin reactivates | Reminders for still-future appointments resume (those within minimum lead are skipped) |
| Therapist deletes account | All future confirmed appointments cancelled with a cancellation email to clients (sent before data erased); personal data erased/anonymized per section 8; token links show "no longer available" |
| Client erasure request (therapist deletes client) | Future appointments are cancelled with notice (default) after confirmation; past appointments anonymized (client fields removed, appointment shell kept for therapist statistics) |
| Client changes email (therapist edit) | Future notifications go to the new email |

### 6.6 Appointment status lifecycle
Statuses: `CONFIRMED`, `CANCELLED_BY_CLIENT`, `CANCELLED_BY_THERAPIST`, `COMPLETED`, `NO_SHOW`. (No PENDING in MVP because booking is auto-confirmed; the architect may model a transient internal state.) Rescheduling is an event on a CONFIRMED appointment, not a status.

| From | To | Who | Condition |
|---|---|---|---|
| (none) | CONFIRMED | Guest, therapist | Slot valid and free |
| CONFIRMED | CANCELLED_BY_CLIENT | Client via token | Before start, within policy window |
| CONFIRMED | CANCELLED_BY_THERAPIST | Therapist | Before start (after start, use COMPLETED/NO_SHOW) |
| CONFIRMED | CONFIRMED (new time) | Client (policy), therapist | Reschedule rules |
| CONFIRMED | COMPLETED | Therapist (S: automatic after end, see OQ-17) | Start has passed |
| CONFIRMED | NO_SHOW | Therapist | Start has passed |
| COMPLETED / NO_SHOW | each other | Therapist | Correction allowed |
| CANCELLED_* | any | nobody | Terminal; re-booking creates a new appointment |

Invalid transitions return a clear conflict error and never change state.

## 7. Privacy and GDPR-supporting requirements

Not a claim of GDPR compliance. These are requirements that support compliance, to be reviewed by a qualified professional before real-world use.

- REQ-PRIV-001 Data minimization: client data limited to name, email, optional phone, time zone; no free text from clients; no health data.
- REQ-PRIV-002 Roles: the therapist is typically the controller for client data and the platform acts as processor for that data, and is controller for therapist account data **Assumption, needs legal review**; documented in privacy policy draft.
- REQ-PRIV-003 Consent/notice: booking requires acknowledging the privacy notice; the notice states what is collected, why, retention and rights; consent timestamp and policy version recorded.
- REQ-PRIV-004 Retention (defaults, OQ-18): client records with no appointment in 24 months and appointment data older than 24 months are anonymized by a scheduled job; cancelled appointment personal data is retained 90 days then anonymized; email delivery logs 30 days; security/audit logs 12 months; tokens expire per REQ-TOKEN-005.
- REQ-PRIV-005 Access/export: therapist can export their own data (profile, appointments, clients) in machine-readable form (JSON/CSV); a client's access request is handled through the therapist who can export that client's record (S) and the platform provides a documented contact route.
- REQ-PRIV-006 Erasure: therapist account deletion (with confirmation and re-authentication) removes or anonymizes all tenant data within a defined period (default: immediate soft-disable then hard delete/anonymization within 30 days, OQ-19); client erasure (REQ-CLIENT-005); backups retention noted in the privacy draft.
- REQ-PRIV-007 Logging: no email, name, phone or token in logs or error messages (use ids).
- REQ-PRIV-008 Emails contain minimal personal data and no health information; therapist-written cancellation messages carry a "do not include health information" hint.
- REQ-PRIV-009 Admin cannot see client personal data (REQ-ADMIN-001).
- REQ-PRIV-010 No third-party trackers/fonts loaded from external CDNs by default (privacy and performance) **Assumption**.
- REQ-PRIV-011 Data is not used for marketing; clients are not auto-subscribed to any list.

## 8. Edge-case catalogue

Each is a requirement to be handled and tested (ID EC-n). Test level hint in brackets: U unit, I integration (Testcontainers), E e2e.

Time zones and DST
- EC-1 Spring-forward date: no slot at nonexistent local times; slots across the gap are correct in real elapsed time [U, I].
- EC-2 Fall-back date: repeated hour handled per BR-TIME-003; two appointments at "01:30" local on different offsets do not conflict [U, I].
- EC-3 Therapist and client in different zones, including different calendar days and one zone on DST while the other is not [U, E].
- EC-4 Appointment booked before a DST change keeps its instant; its local display after the change is correct [I].
- EC-5 Zones with half/45-minute offsets, southern-hemisphere DST, zones that abolished DST [U].
- EC-6 Therapist changes zone with future appointments (REQ-AVAIL-006) [I, E].
- EC-7 Invalid/unknown zone id from client or input rejected; client with unrecognised browser zone falls back to therapist zone with notice [U].
- EC-8 Reminder times near DST changes (24 hours before is elapsed time) [U].
- EC-9 Max-advance cut-off and minimum notice evaluated across DST [U].
- EC-10 Server runs in a different zone than any tenant; behaviour is identical (no implicit default zone) [I].
- EC-11 Appointments at the extremes: 00:00 and 23:xx local ranges (single-day only) [U].

Concurrency and duplicates
- EC-12 Two simultaneous bookings for the same slot: exactly one winner, other receives a conflict [I with real PostgreSQL, parallel threads].
- EC-13 Overlapping but not identical slots (different session types/durations, buffers) racing [I].
- EC-14 Booking vs therapist-created appointment vs reschedule racing for the same time [I].
- EC-15 Double click / retry with the same idempotency key returns one appointment, one email [I, E].
- EC-16 Same key reused with a different payload is rejected [I].
- EC-17 Two reschedules of the same appointment racing; cancel racing with reschedule [I].
- EC-18 Cancel twice; cancel after start; cancel exactly at the deadline (inclusive boundary, section 6.3: allowed at exactly the deadline) [U, I].
- EC-19 Slot taken between selection and submit: user gets message and fresh slot list, keeps entered details [E].
- EC-20 Same person booking overlapping appointments with the same therapist (allowed? default rejected as it overlaps; sequential allowed) up to the per-email limit [I].
- EC-21 Same client email booking with two different therapists at the same time: allowed (no cross-tenant link) [I].

Tokens
- EC-22 Wrong, truncated, malformed, expired token: identical neutral response and similar timing [I].
- EC-23 Token of appointment A used on B's resource path: denied [I].
- EC-24 Token page after cancellation: shows cancelled state, no actions [E].
- EC-25 Token enumeration attempts are rate limited [I].
- EC-26 Link opened by email security scanners (prefetch): GET must never cancel; actions require explicit POST with a confirmation step [I, E].
- EC-27 Token after account disable/deletion (OQ-16) [I].
- EC-28 Token leakage via Referer or logs [I: header checks].

Availability and booking validity
- EC-29 Booking in the past, now, inside minimum notice, beyond the advance window: rejected server-side even if the UI is bypassed [I].
- EC-30 Zero availability: empty state; therapist with no hours cannot be published [E].
- EC-31 Slot appears in UI but session type deactivated, therapist unpublished or disabled in the meantime: rejected with clear message [I].
- EC-32 Availability edited with future conflicting appointments: no auto-cancel, conflicts listed [I, E].
- EC-33 Overlapping working ranges entered for the same day: validation error [U].
- EC-34 Break outside working hours or covering everything: validated or ignored predictably [U].
- EC-35 Date block overlapping an existing appointment: warning, appointment remains [I].
- EC-36 Duration longer than any working range: no slots; therapist warned [U].
- EC-37 Duration/buffer/notice of zero and maxima [U].
- EC-38 Booking exactly at working-hours start/end boundaries; appointment ending exactly at range end allowed; starting at range end not [U].
- EC-39 Leap day, month and year boundaries in month view and max advance [U].

Account and tenant
- EC-40 Therapist A requests B's appointment/client/profile by id: not found/forbidden, no data leak, including list, search, export, calendar and dashboard [I, security].
- EC-41 Tenant id in request body/path ignored; derived from principal [I].
- EC-42 Disabled therapist: login blocked, existing session/token rejected on next request, public page hidden, new bookings blocked [I].
- EC-43 Wrong role calls admin endpoints; admin calls therapist-owned data endpoints [I].
- EC-44 Brute-force login; password reset abuse; registration with an existing email returns generic response (S, if verification exists) [I].
- EC-45 Session expiry mid-edit in the dashboard: no data loss for forms where feasible, redirect with return path [E].
- EC-46 Slug collisions, reserved slugs, unicode/homoglyph slugs, slug change [U, I].
- EC-47 Account deletion with future appointments and pending emails (clients still notified; no email sent after erasure with personal data missing) [I].
- EC-48 Deleting a client who has future appointments [I].

Content and input
- EC-49 Very long names (100+ chars), long bios, many specializations: truncation with accessible full text, layout does not break [E, visual].
- EC-50 Unicode names, right-to-left text, emoji, apostrophes, plus-addressing and international phone formats [U].
- EC-51 HTML/script injection in all text fields and email templates (header injection too) [I, security].
- EC-52 Oversized or wrong-type photo uploads, corrupted images [I].
- EC-53 Discovery with no results, filters that exclude everything, page beyond last, thousands of therapists (pagination) [E, I].
- EC-54 Demo vs real data: demo flagged everywhere it appears [E].

Notifications and operations
- EC-55 SMTP down: booking succeeds, email retried with backoff, then FAILED and visible [I].
- EC-56 Worker crash mid-send / application restart: no loss; no duplicate send beyond the dedup guarantee [I].
- EC-57 Two application instances process the queue: no duplicates [I].
- EC-58 Appointment cancelled or rescheduled after the reminder was queued: reminder skipped or replaced [I].
- EC-59 Invalid/bounced email address: delivery failure flagged to the therapist; no infinite retries [I].
- EC-60 Booking made after the reminder time already passed (appointment within 24 h): no reminder is sent; confirmation only [U].
- EC-61 Email template renders correctly with long names and non-Latin characters; zone names clear [U].
- EC-62 Clock skew and jobs delayed past appointment start: reminder skipped (REQ-NOTIF-010) [U].

Past dates and lifecycle
- EC-63 Calendar navigation to the far past/future: bounded without errors; creating past appointments by therapist allowed for record keeping (marked completed) **Assumption** (OQ-20) [E].
- EC-64 Marking completed/no-show before start: rejected [U].
- EC-65 Appointment end after the start of a later working range; midnight crossing excluded (BR-TIME-005) [U].

## 9. Acceptance criteria (critical flows)

IDs AC-x trace to REQs.

Booking (REQ-BOOK-001..006, 009, 011)
- AC-BOOK-1 Given a published therapist with Monday 09:00-17:00 Europe/Berlin and a 50-minute session, when a guest views Monday's slots in Europe/London, then each slot shows the London time and the Berlin time, and the last slot ends by 17:00 Berlin.
- AC-BOOK-2 Given an open slot, when the guest submits valid details with consent, then the appointment is CONFIRMED, the response contains the appointment details, one confirmation email is queued to the guest, and the slot disappears from subsequent availability.
- AC-BOOK-3 Given two guests submit the same slot simultaneously, when both requests are processed, then exactly one succeeds and the other receives a conflict with no appointment created and no email sent.
- AC-BOOK-4 Given a submission is repeated with the same idempotency key, when the second request arrives, then the response references the same appointment and only one email exists.
- AC-BOOK-5 Given a request bypasses the UI for a slot inside the minimum notice period, in the past, or beyond the advance window, when submitted, then the backend rejects it with a validation error.
- AC-BOOK-6 Given consent is not given or the email is invalid, when the guest submits, then no appointment is created and the form shows field-level errors that are announced to assistive technology.
- AC-BOOK-7 Given SMTP is down, when a booking is made, then the booking succeeds and the confirmation screen shows the details; the email is retried and eventually marked failed after the cap.
- AC-BOOK-8 Given a guest's email belongs to an existing client of the therapist, when they book, then the response and UI are identical in form to a new client's.

Availability and slots (REQ-AVAIL, BR-SLOT/TIME)
- AC-AVAIL-1 Given a 30-minute buffer and an appointment 10:00-10:50, when slots are computed for 50-minute sessions, then no slot starts before 11:20 (assuming grid permits) and 10:00 and 10:50 not offered.
- AC-AVAIL-2 Given America/New_York on the spring-forward date, when slots are computed for working hours 01:00-04:00, then no slot is offered with a local start from 02:00 to 02:59 and total offered elapsed time is 2 hours.
- AC-AVAIL-3 Given the fall-back date with working hours 00:00-03:00, when slots are computed, then both occurrences of the repeated hour are offered as distinct instants with offsets shown (per BR-TIME-003).
- AC-AVAIL-4 Given a date block on a day with an existing confirmed appointment, when saved, then the appointment remains CONFIRMED and the therapist sees it listed as a conflict.
- AC-AVAIL-5 Given a day with no working hours, when the guest selects it, then an empty state with the next available date is shown.
- AC-AVAIL-6 Given minimum notice 12h, when it is 08:00 local, then slots starting before 20:00 today are not offered.

Cancellation (REQ-CANC)
- AC-CANC-1 Given freeCancellationHours = 24 and an appointment in 30 hours, when the client opens the token link and confirms cancel, then the status becomes CANCELLED_BY_CLIENT, the slot becomes bookable, and cancellation emails go to both parties.
- AC-CANC-2 Given the same appointment is now 23 hours away, when the client opens the link, then no cancel action is offered, the policy and therapist contact are shown, and a direct API cancel call is rejected.
- AC-CANC-3 Given the exact boundary (start minus 24h), when the client cancels at that instant, then it is allowed.
- AC-CANC-4 Given a cancelled appointment, when cancel is called again, then it returns success with unchanged state and no second email.
- AC-CANC-5 Given a link-preview bot issues GET on the token URL, then no state change occurs.
- AC-CANC-6 Given a therapist cancels within the client's policy window, then it is allowed and the email says the therapist cancelled.

Rescheduling (REQ-CANC-006..008)
- AC-RESCH-1 Given an eligible appointment, when the client selects a free new slot and confirms, then the appointment has the new time, the old slot is free, one reschedule email is sent, and reminders are re-planned.
- AC-RESCH-2 Given the new slot is taken concurrently, when the client confirms, then the request fails with conflict and the original appointment remains unchanged and confirmed.
- AC-RESCH-3 Given a therapist reschedules to a time overlapping another confirmed appointment, then it is rejected even with the availability override enabled.
- AC-RESCH-4 Given an appointment beyond the policy window, when the client attempts reschedule, then it is denied with the policy explanation.

Authentication and authorization (REQ-AUTH)
- AC-AUTH-1 Given valid credentials, when the therapist logs in, then they reach the dashboard; given invalid credentials for an existing or non-existing email, then the same generic error is shown.
- AC-AUTH-2 Given N consecutive failed logins (N per architecture), when another attempt occurs, then it is throttled/locked and the response does not disclose account existence.
- AC-AUTH-3 Given a disabled therapist with a valid password, when they log in, then access is denied with the disabled-account message; an existing session stops working at the next request.
- AC-AUTH-4 Given a non-admin, when calling an admin endpoint, then 403; given an unauthenticated user calling therapist endpoints, then 401.
- AC-AUTH-5 Given password change with a wrong current password, then it fails and nothing changes; with the right one, other sessions end.

Tenant isolation (REQ-NFR-007)
- AC-TEN-1 Given therapists A and B each with appointments and clients, when A requests B's appointment, client, or calendar entries by id, then the response is not-found/forbidden with no data of B disclosed, for each therapist-owned resource and operation (read, update, cancel, reschedule, export).
- AC-TEN-2 Given A's list/search/dashboard/calendar endpoints, then results contain only A's data, including aggregate counts.
- AC-TEN-3 Given a request body containing B's tenant id, when A calls any endpoint, then the id is ignored or rejected and no write occurs in B's data.
- AC-TEN-4 Given a token for A's appointment, when used against any other appointment or a therapist endpoint, then it is denied.

Notifications (REQ-NOTIF)
- AC-NOTIF-1 Given a confirmed appointment 48h away and a 24h reminder setting, when the worker runs at T-24h, then exactly one reminder is sent, even with two workers or a restart in between.
- AC-NOTIF-2 Given the reminder is queued and the appointment is cancelled, then no reminder is sent.
- AC-NOTIF-3 Given SMTP fails, then retries use backoff up to the cap and then status FAILED is visible to the therapist.

Privacy (REQ-PRIV)
- AC-PRIV-1 Given a therapist deletes their account, then future appointments are cancelled with client emails, and the tenant data is removed or anonymized per retention, and public pages and tokens stop resolving.
- AC-PRIV-2 Given the booking form, then it contains no free-text or health fields.
- AC-PRIV-3 Given application logs from a booking test run, then no email, name, phone, or token appears.

## 10. Open questions

Each has a recommended default; the Lead may adopt the default without asking the user unless marked **[USER]** or **[ARCH]**.

| ID | Question | Recommended default and reason |
|---|---|---|
| OQ-01 | Is a tenant one therapist or a practice with multiple therapists? **[USER]** | MVP: one therapist per tenant, with practice details as profile fields; multi-staff later. Greatly simplifies calendars, permissions and slot logic. Architect should avoid blocking a later upgrade. |
| OQ-02 | Do client-facing booking pages live under therapist slug (e.g. /t/{slug})? | Yes, human slug; exact URL scheme `[ARCH]`. |
| OQ-03 | Slot start grid: fixed interval (15/30/60), or equal to session duration? | Therapist-configurable grid (15, 30, 60; default 30). Common in comparable tools and flexible for varied durations. |
| OQ-04 | Hold slot while client fills the form? | No hold in MVP; the final submit decides, with graceful conflict UX (EC-19). A temporary hold adds state and abuse risk. |
| OQ-05 | May therapists override hours/notice when creating/rescheduling? | Yes, with an explicit confirmation; never override overlap. Real-world flexibility. |
| OQ-06 | Reminder timing and channels? | Email only; client default 24h before, therapist choice of off/2/24/48h. |
| OQ-07 | Behaviour on therapist time zone change? | Keep instants; warn with count; do not shift appointments. Safest for clients who already hold links. |
| OQ-08 | Token lifetime? | View until appointment end + 30 days; act until the policy deadline. Limits exposure. |
| OQ-09 | Max upcoming bookings per email per therapist? | 3 (anti-abuse); configurable later. |
| OQ-10 | CAPTCHA/bot challenge on booking? **[ARCH]** | Rate limits plus an invisible/privacy-friendly challenge only if abuse appears; avoid third-party trackers (REQ-PRIV-010). |
| OQ-11 | May therapists store a free-text note on a client? | No in MVP: even "scheduling notes" drift into clinical notes. Revisit later with explicit guardrails. |
| OQ-12 | Old slug redirects after slug change? | Yes, 90 days. Prevents broken shared links. |
| OQ-13 | Fall-back repeated hour: offer both occurrences or first only? | Offer both with offsets labelled if inside working hours; alternative simpler option is first only. Architect/Lead may choose the simpler option; must be tested either way. |
| OQ-14 | Support working ranges across midnight? | No (single local day). |
| OQ-15 | Snapshot cancellation policy at booking? | Yes: fair to the client and avoids retroactive surprises. |
| OQ-16 | What happens to future appointments if admin disables a therapist? | Do not cancel automatically; suspend new bookings and reminders; link page shows a contact notice; admin may later bulk-cancel. Needs human confirmation **[USER]** for abuse cases (fraud: cancel and notify). |
| OQ-17 | Auto-mark past confirmed appointments as COMPLETED? | Yes, a daily job marks unmarked CONFIRMED appointments COMPLETED 24h after the end; therapist can correct to NO_SHOW. Keeps history tidy. |
| OQ-18 | Retention periods? **[USER], legal review** | 24 months for appointment/client data after last activity, 90 days for cancelled appointment PII, 30 days delivery logs, 12 months audit logs. Placeholders, not legal advice. |
| OQ-19 | Account deletion timeline and backups? | Immediate disablement, hard delete within 30 days; backup expiry documented. |
| OQ-20 | May therapists back-date appointments? | Yes (for importing history), created as COMPLETED, no emails. |
| OQ-21 | Therapist email verification mandatory to publish? | Yes (S): reduces fake profiles; needs SMTP in all environments. |
| OQ-22 | Is the therapist copy of booking emails default on? | Yes; configurable. |
| OQ-23 | Admin creation and MFA for admin **[ARCH]** | Seed via config/migration for local; documented process for prod; MFA later. |
| OQ-24 | Photo storage (database, filesystem, object storage) **[ARCH]** | Architect decision; MVP local volume acceptable. |
| OQ-25 | Auth mechanism, rate-limit storage, idempotency key storage, queue mechanism, concurrency approach **[ARCH]** | ADRs by the Architect; requirements above define the outcomes. |
| OQ-26 | Discovery ordering and fairness | Alphabetical (no ranking claims) in MVP; avoid implying endorsement. |
| OQ-27 | Do we offer therapists' emails/phones publicly? | No by default; opt-in per field. |
| OQ-28 | Which languages for the UI? | English only; i18n-ready strings. |
