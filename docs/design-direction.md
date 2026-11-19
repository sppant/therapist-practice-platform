# Design Direction

**Everything in this document is the team's own proposal.** It is informed by the structural and accessibility findings in `docs/design-research.md` but no typography, color or spacing value was taken from a reference product (the research could not retrieve them). Contrast ratios were computed by the frontend-engineer with a python3 script and must be re-verified in the browser during the foundation phase.

Lead decisions applied: booking order type -> date -> time -> details -> confirmation (type step skipped when only one session type; "Next available" shown and suggested, never auto-committed; date and time side by side on desktop); **no reason-for-visit field** (see `docs/product-requirements.md` section 3); dark mode out of MVP; statuses per the requirements lifecycle; no fabricated testimonials, ratings or statistics; monogram avatars only.

## 1. Principles
1. Calm before clever: one accent action per view, no decorative effects.
2. Availability first, identity second: show real times before asking for personal details.
3. Privacy is visible: plain-language statements, not badge icons (e.g. "We only use this to confirm your appointment").
4. Warm, editorial, human: warmth from color and type, not illustration everywhere.
5. The product is the hero: marketing shows a real UI built in code.
6. Time is never ambiguous: zone shown whenever the viewer's zone differs from the therapist's; dates are never relative-only.
7. Keyboard and screen-reader parity.

## 2. Typography
- Newsreader 400-600 for headings, marketing and a few brand moments only. Inter for all UI, with tabular-nums for times, tables and calendar. Serif never in tables or slot labels.
- Both are believed to be SIL OFL and self-hosted. **License and axes to be verified during the foundation phase** (the specimen pages could not be fetched).
- Self-hosting via @nuxt/fonts or @fontsource-variable is a dependency decision for the architect and engineer. font-display swap with a size-adjust fallback.
- Scale in rem (mobile / desktop):

| Role | Size | Line height | Face / weight |
|---|---|---|---|
| display (home hero only) | 2.5 / 3.5 | 1.1 | serif 500 |
| h1 | 2 / 2.5 | 1.15 | serif 500 |
| h2 | 1.5 / 1.75 | 1.25 | serif 500 |
| h3 | 1.125 / 1.25 | 1.35 | sans 600 |
| body-lg | 1.125 | 1.6 | sans |
| body | 1 (16px minimum for inputs) | 1.55 | sans |
| small | 0.875 | 1.45 | sans |
| caption | 0.75 | 1.4 | sans 500 (never the only carrier of essential info) |

Letter-spacing -0.01em on serif display, else 0. Max 65ch prose.

## 3. Color tokens (light only)
Tokens are CSS variables so a dark theme can be added later. Declare `color-scheme: light`. No violet or indigo anywhere, no gradients on chrome, no glow or blur, warm-tinted neutrals, accent on at most one control per view.

| Token | Value | Notes |
|---|---|---|
| canvas | #FAF7F2 | page background |
| surface | #FFFFFF | |
| sunken | #EEEBE5 | |
| border-subtle | #E3DED5 | decorative only |
| border-control | #7C8782 | 3.72:1 on white |
| ink | #1F2A27 | |
| ink-secondary | #4A5551 | |
| ink-muted | #5E6A66 | |
| primary | #2F6B5E | |
| primary-hover | #255A4E | |
| primary-strong | #1F4F45 | focus ring, text on tint |
| primary-tint | #E6F0EC | |
| accent text (clay) | #9A4B2E | |
| accent decorative | #B5603F | non-text only; white on it is 4.46 and fails, so no white-on-clay buttons |
| success | #1E6B3A on #E7F3EA | |
| warning | #8A5A00 on #FBF0D9 | |
| danger | #A93226 on #FBE9E6; solid #B3261E | |
| info | #1D5C85 on #E5F0F7 | |

Contrast ratios (computed by the frontend-engineer, to be re-verified): ink on canvas 13.85; ink on white 14.8; ink-secondary on canvas 7.25; ink-muted on canvas 5.27, on white 5.63, on sunken 4.73 (tight; 14px minimum there); primary on canvas 5.8; white on primary 6.2; white on primary-hover 7.92; primary-strong on primary-tint 7.97; accent text on canvas 5.75; success pair 5.72; warning pair 5.24; danger pair 5.64; white on danger solid 6.54; info pair 6.21; focus ring on canvas 8.69; border-control #7C8782 on white 3.72 (the lighter #8A948F gave 2.93 and fails 3:1 on canvas); disabled text #8A948F on sunken 2.63 (acceptable only because disabled controls are exempt).

### Status styling
Always color + icon + text label. Statuses follow the requirements lifecycle (no PENDING).

| Status | Style |
|---|---|
| CONFIRMED | success pair + check icon |
| COMPLETED | neutral #4A5551 on #EEEBE5 + double-check icon |
| CANCELLED_BY_CLIENT / CANCELLED_BY_THERAPIST | muted #5E6A66 on #EEEBE5 (4.73) + x icon; strikethrough time in calendar blocks; label says who cancelled |
| NO_SHOW | #6B3F5E on #F5E9F1 (7.13) + minus icon. Muted mauve-plum: must be checked on a real screen so it does not read as purple; fall back to danger if it does |
| Rescheduled (an event shown in history, not a status) | info pair + arrow icon |

Calendar blocks: 3px left status bar plus tinted fill.

## 4. Spacing, radii, elevation, sizing
- 4px base scale: 4, 8, 12, 16, 24, 32, 48, 64, 96. Marketing section padding 64 mobile / 96 desktop; card padding 16/24; field gap 16; label-to-input 6-8.
- Radii: 6 (inputs, chips, badges), 10 (buttons, slots, cards), 16 (modals, hero frames), full only for avatars and pills; at most two radius values per screen; no nested large radii.
- Elevation: flat cards separated by whitespace and a 1px subtle border. Shadows only for floating layers: popovers `0 4px 16px rgb(31 42 39 / 0.08)`, modals `0 12px 32px rgb(31 42 39 / 0.14)` with scrim `rgb(31 42 39 / 0.4)`. Borders define controls (3:1) and table rows; do not box every card.
- Breakpoints: Tailwind defaults sm 640, md 768, lg 1024, xl 1280, 2xl 1536. Dashboard sidebar from lg; calendar week view from md; day and month work on mobile.
- Sizing: buttons and inputs 44px high (48px primary CTAs on mobile); icon buttons 44x44 hit area; booking-widget day cells and slot buttons at least 44px with 8px gaps; gutters 16/24/32; max width 1200 marketing, 1440 app.

## 5. Interaction states
- Hover: next darker fill step or sunken fill. Active: one step darker, no translate.
- Focus-visible: 2px solid #1F4F45, 2px offset, plus a white inner ring on dark fills; never clipped by overflow hidden.
- Disabled: sunken fill, #8A948F text, cursor-not-allowed, aria-disabled where it must stay focusable.
- Loading: spinner in the same width, aria-busy, visually-hidden label kept.
- Selected: primary-tint fill, 2px primary border, check icon.

## 6. Motion
- 120ms hover/press, 200ms small transitions, 300ms panels/drawers/modals, never above 400ms. Ease-out `cubic-bezier(0.2,0,0,1)` entering, ease-in `cubic-bezier(0.4,0,1,1)` exiting; no bounce or spring. Animate only opacity and transform. Calendar grid navigation swaps instantly (optional 150ms fade).
- `prefers-reduced-motion`: replace slides and scales with instant change or at most a 100ms fade; stop skeleton shimmer; scroll-behavior auto.
- No timing-dependent behavior (Playwright runs with reduced-motion emulation).

## 7. Screen concepts

**Homepage.** Serif H1 promise (e.g. "Find a therapist and book in a minute."), one support line, one primary CTA "Find a therapist" plus a text link "I'm a therapist", a code-rendered booking widget as the hero visual. Intent chooser chips (Anxiety, Relationships, Life transitions, Trauma, Not sure) linking to filtered discovery. Three-step how-it-works; plain-language "Why this is private"; therapist section with calendar mockup; FAQ accordion; footer with privacy, accessibility statement and crisis-resources link. No testimonials, ratings or statistics (all data is demo data).

**Discovery.** Sticky left filter rail on desktop, full-height filter sheet on mobile. Filters: specialty (with counts), session format, location, language, availability. Removable active-filter chips with Clear all. Single-column cards (two columns at xl) with monogram avatar, name, credentials, one-line approach, max 3 chips, format, "Next: Tue 10:30"; the whole card is one link target. Result count in a polite live region; sort by relevance or earliest availability.

**Profile.** Two columns at lg (profile left, sticky booking card right). Mobile uses a sticky bottom "Book" bar opening a full-screen sheet. "What to expect at your first session" collapsible. Credentials disclaimer and "Demo content" label where applicable.

**Booking flow.** Stepper "Step 2 of 4"; an h1 per step that receives focus on step change; Back always available. Type step is skipped for a single session type. "Next available: ..." at the top suggests the earliest slot but never auto-commits it. Date step: month calendar with availability dots plus a horizontally scrolling week strip on narrow screens; date and time side by side on desktop. Time step grouped Morning/Afternoon/Evening, times in the client's zone, zone stated once above the list with a change-zone control. Details step: name, email, optional phone, privacy consent, summary card, with the line "We only use this to confirm your appointment". **No reason-for-visit field** and no health questions. Inline errors plus an error summary that receives focus. Confirmation: "You're booked." with summary, Add to calendar, Manage or cancel link, and a note that a confirmation email was sent.

**Dashboard overview.** Serif greeting and date; "Today" list as main column; right column "Needs attention" and a compact week-ahead strip; quick actions "Block time" and "Share booking link"; no KPI-tile wall. Sidebar nav (Overview, Calendar, Appointments, Clients, Availability, Settings) 240px, icon rail at md, bottom tab bar on mobile.

**Calendar.** Toolbar: Today, prev/next, date label (live region), segmented Day/Week/Month, time-zone label. Week view: 64px time gutter, hour lines border-subtle, working hours canvas fill and non-working hours a subtle sunken tint, "now" line in #9A4B2E 2px with dot. Blocks: radius 6px, status tint, 3px status bar, client name 600 plus type, status icon, one line under 30 min. Month cells show up to 3 items plus a "+2 more" popover; mobile month grid with count dots and the selected day's list below; day view default on mobile. Clicking a block opens a right-hand drawer, not a page. A List alternative for screen-reader users. Shortcuts T, D, W, M, arrows with a ? help dialog. DST days render 23/25 hours (requirements REQ-CAL-005).

**Availability editor.** Seven day rows each with toggle, one or more time ranges, Add range, Copy to...; separate date overrides and time-off list with an Add exception dialog; live preview of the next two weeks as clients will see them; inline validation naming overlapping ranges; time zone shown prominently.

**Appointments table.** Sticky header; columns Date/time (tabular figures), Client, Type, Status badge, Actions kebab; filters: status chips, date range, name search; row opens the drawer; pagination with announced total; aria-sort; mobile collapses to cards; empty state with one sentence and a primary action.

**Mobile navigation.** Public site: top bar with full-screen menu dialog (focus trap, Esc closes). Dashboard: bottom tab bar Overview, Calendar, Appointments, More (sheet with Clients, Availability, Settings, Sign out); 44px items, labels always visible, aria-current="page".

## 8. Imagery
- Deterministic monogram avatars on six muted fills chosen from a hash of the therapist id: sage #DCE9E3, sand #EADFCB, clay #F0D9CC, stone #E4E2DC, sky #DCE8EE, moss #E3E8D3, with matching dark text that must reach 4.5:1 (**not yet verified**). No photos in demo data; the README must state that all data is demo data. The backend still supports uploaded photos later (square crop shown as circle, monogram fallback, alt equals the name or is empty when the name is adjacent). Optional abstract organic-shape avatar variant.
- Marketing imagery: product UI in code plus in-house abstract botanical or line illustrations in primary and accent-decorative. No AI-generated faces. AVIF/WebP with explicit width and height and lazy loading below the fold.

## 9. Accessibility for calendar, date picker and slots
- Date grid: role=grid labelled by the month heading (h2, aria-live=polite); th abbr for day names; roving tabindex; aria-selected on the chosen day only; APG key handling (arrows, Home/End, PageUp/PageDown, Shift+PageUp/Down, Enter/Space, Esc). Cell accessible name "Tuesday 14 October 2026, 6 times available" or "no times available". Unavailable days are aria-disabled and still focusable with the reason announced via the status line. Today is marked in text and with a non-color cue. A typed "Go to date" fallback.
- Slots: radiogroup (native radio inputs styled as buttons) with a visible group label including the zone; selected state by border plus fill plus check icon; arrow-key navigation. Booked slots hidden by default with "fully booked, next available: ..." text (hide versus grey is a judgement call to test with users; no evidence retrieved).
- Time zone name and offset shown above slots and on confirmation via Intl.DateTimeFormat with explicit timeZone.
- One polite live region for async status; an assertive region only for blocking errors such as "That time was just booked. Please choose another." with focus returned to the slot list. Focus to the step heading on step change and to the error summary on failed submit.
- 44px targets, 2px focus ring, reflow to 320px, slot grid collapses to one column at 200% text.
- Staff calendar: List alternative; blocks reachable in chronological order with names like "10:00 to 10:50, Anna K., Confirmed"; any drag-and-drop has a non-drag Reschedule alternative (WCAG 2.5.7).
- Forms: visible labels, autocomplete tokens, required marked in text, aria-describedby errors, error summary, scroll-and-focus the first invalid field.

## 10. Micro-interactions worth building (all reduced-motion safe)
Slot selection with summary card 150ms fade; booking step fade plus 8px slide with focus to heading; "Next available" chip jumps the calendar and focuses the first slot; calendar now-line, jump-to-today and shortcuts; optimistic status change with undo toast; layout-matching skeleton loaders; filter chip changes announcing the result count; width-stable button loading; availability live preview; copy-booking-link with an announced "Copied".

## 11. Open items
- Verify font licenses and axes (Newsreader, Inter).
- Verify all derived avatar and status color pairs; re-verify the full palette contrast in the browser.
- Decide hide-versus-grey for booked slots through user testing.
- Human visual review of live references (Awwwards, Godly, Land-book, Dribbble); the one research gap.
- Confirm the no-show color does not read as purple.
- Decide the font self-hosting dependency (architect and frontend engineer).
