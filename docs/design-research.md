# Design Research

Status: Phase 1, compiled from the frontend-engineer's web research. Read the limitation first.

## 1. Method and limitation (read first)

The research tool (WebFetch) returned **text only**: no rendered visuals, no CSS, no screenshots. Reference-level claims about typography, color and spacing of real products were therefore **not obtained**. The only color facts retrieved are incidental Calendly SVG artwork fills and one retrieved concept palette (Ivyhearth, section 4). Everything in `docs/design-direction.md` for type, color and spacing is **the team's own proposal**, not derived from the references.

What the research did yield: information architecture, section order, interaction patterns and accessibility guidance. It did not yield rendered visual style.

The document keeps three categories separate:
- **Retrieved**: what was actually fetched, with URL.
- **Inference**: our reading of retrieved material (not a fact about the site).
- **Proposal**: lives in `design-direction.md`.

Items marked "text only" or "snippet only" were not seen visually.

## 2. Retrieved references

### Product references (text-only unless noted)

| # | Reference | Retrieved | Lesson / inference |
|---|---|---|---|
| 1 | Cal.com https://cal.com | One clear promise, three plain CTAs. Section order: Scheduling, Events, Discover, Features, Customer stories, Benefits, Pricing, Enterprise, FAQ, Developers. | Lesson: a single promise and few CTAs. |
| 2 | Cal.com v6.6 changelog https://cal.com/blog/calcom-v6-6 and https://alternativeto.net/news/2026/6/cal-com-v6-6-introduces-major-ui-overhaul-live-event-previews-admin-audit-logs/ | Moved to "coss.com/ui" (built on Base UI); live booker preview beside scheduling-link settings; rebuilt sidebar, bookings list and drawer, tables, timezone slider; booker scrolls to the first missing required field on a failed submit; a theme flicker on initial load was fixed. | Lessons: live preview beside settings; a drawer for booking details; scroll-and-focus to the first invalid field; care with theme flicker under SSR. |
| 3 | Cal.com blog index https://cal.com/blog | Titles only, including a Nov 2025 incident review after a bookings-page redesign caused usability problems. | Inference: give every view deterministic loading, empty and error states, and test them. |
| 4 | Headspace https://www.headspace.com (text only) | Leads with an intent question ("What kind of headspace are you looking for?", six options including "Start therapy"); tabbed card grid; stacked FAQ; illustrated characters instead of people; multi-width auto-format images. | Lesson: lead discovery with an intent chooser. Inference: warm accents carry personality over a calm base. |
| 5 | Calendly https://calendly.com | Hero reduces friction (one-click signup, "No credit card required"); metric-led testimonials; numbered steps. Hex values found are **artwork fills, not confirmed UI colors**: blues #E5EFFB #F5F8FC #C3DFFE #4793EB #2E7DD7 #092B52; warm #FFC6BD #FF9585 #FFE67C; purples #C5AFFE #A381F8; blurred/noise gradient artwork (feGaussianBlur, feTurbulence). | Anti-lesson (inference): blurred gradients and purple accents are the generic AI-SaaS look we want to avoid. |
| 6 | Linear https://linear.app (text only) | Real product UI used as the hero visual; "Fig 0.1" labelled blocks; dated changelog. | Lesson: show a real calendar mockup built in code, not stock art. |
| 7 | Notion Calendar https://notion.com/product/calendar (text only) | Multi-timezone day view; command menu and keyboard shortcuts; drag and drop; auto-blocking busy time. | Lesson: keyboard-first calendar (T today, D/W/M views, arrows) and time-zone clarity. |
| 8 | Talkspace https://www.talkspace.com (text and asset names) | Privacy badges; numbered "how it works"; therapist cards; specialty tag list; crisis notice with link in footer. | Lesson: trust cues are expected in this category; include a privacy statement and a crisis-resources footer link. |
| 9 | Alma https://helloalma.com (text only) | Primary CTA "Find a therapist"; separate provider path; location directory pages; accessibility-statement link in footer. | Lesson: directory pages suit Nuxt SSR and SEO; provide an accessibility statement. |
| 10 | Stripe https://stripe.com (text and asset names) | Bento grid; mobile-specific image variants; large-figure stats with short captions. | Lesson: a stats band only sparingly; we have no real stats, so invent none. |
| 11 | Awwwards wellness list https://www.awwwards.com/websites/wellness/ | List of 31 titles only. | Nothing visual concluded. |
| 12 | Therapy-site roundups (search snippets only, pages not opened): https://creativepool.com/mutatio/projects/megan-williams-psychotherapy-website , https://www.designrush.com/best-designs/websites/lauren-lowe-therapy-website-design , https://insidea.com/customers/websites/ivyhearth-concept , https://www.framer.com/community/marketplace/templates/maria-psy/ | Agency and template marketing claims, not measured outcomes: soft neutrals, serif headline plus sans body recurring. | Weak evidence; treat as a hint only. |

### Guidance references

| # | Reference | Retrieved | Lesson |
|---|---|---|---|
| 13 | W3C APG Date Picker Dialog https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/examples/datepicker-dialog/ (full text) | role=grid labelled by the month heading; roving tabindex; aria-selected on the chosen cell only; arrows / Home / End / PageUp / PageDown / Shift+PageUp/Down / Enter / Space / Esc; aria-live=polite month heading. | Basis for the date grid keyboard model. |
| 14 | WCAG 2.2 SC 2.5.8 https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html | AA minimum target 24x24 CSS px. | Our 44px target is a deliberate internal standard, stricter than AA. |
| 15 | Smashing Magazine (2017, dated) https://www.smashingmagazine.com/2017/07/designing-perfect-date-time-picker | Show availability in the calendar itself; mark today; full-screen overlay on narrow screens; announce selection to screen readers. | Dated source; patterns still plausible. |
| 16 | CDS-SNC booking patterns https://cds-snc.github.io/project-docs/booking/design-patterns (several items marked hypotheses by the page itself) | Show availability before personal info; show the next available early; preselect the first time; avoid month views that require a date before times appear. | Hypotheses, not proven. We adopt "next available" but do not auto-commit a slot. |
| 17 | Radix Colors scale https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale | 12-step role-based scale. | We structure tokens by role; no Radix hex values are used. |
| 18 | Fraunces README https://raw.githubusercontent.com/undercasetype/Fraunces/master/README.md | Considered, not chosen. License not stated in the README. | Not used. |

Search-snippet-only: date-picker accessibility pages (MUI, Carbon, USWDS, Toyota, Axess Lab) and time-slot UX pages (Baymard, paywalled; Eleken; Square). Only snippet claims used: purpose-specific date labels, allow typed dates, show availability in the client's time zone.

### Ivyhearth concept palette (retrieved)
Linen #F4EEE4, Green #2E3A2F, Terracotta #B86B4B, Sand #D9CBB4, Paper #FBF8F2, with fonts Manuale and Karla. Source: https://insidea.com/customers/websites/ivyhearth-concept (a concept project; an example of a warm neutral and green palette, not evidence of outcomes).

## 3. Could not access

zocdoc.com (403); calm.com (403); doctolib.fr (403); land-book.com (403); godly.website (301 cross-host redirect to recent.design, not followed); dribbble search (empty or blocked); headspace.com/design-systems (404); alma.com (wrong site; the correct one is helloalma.com, ref 9); Cal.com repo tailwind-preset (404); Google Fonts specimen pages for Fraunces and Inter (title only); fontshare General Sans (no data); Behance (not attempted).

## 4. Bottom line

There are 18 retrieved entries, but many are text-only and five (refs 13 to 17, which include the dated 2017 Smashing article) are guidance pages rather than product visuals. Only refs 4 to 10 are real products, and none exposed typography or palette. What was gained is structure, information architecture, interaction patterns and accessibility guidance, not rendered visual style.

**The one gap:** a human or browser-based visual review of live references (including Awwwards, Godly, Land-book, Dribbble) is recommended during the design-system phase. Until then, the visual direction rests on the team's proposals.
