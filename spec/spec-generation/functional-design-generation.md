# Functional Design Plan — Next.js Modernization

## Context Analyzed
- `spec/plans/requirements.md`, `spec/plans/stories.md`, `spec/plans/application-design.md` read.
- `spec/plans/atlas-deep-dive.md` — existing business logic (MVC controllers, Active Record models) is the source of truth for domain rules, since this is a like-for-like re-platform, not new functionality.
- No Context References registered — N/A.

**Framing**: since this migration explicitly preserves existing behavior (REQ-NF-01 API parity, REQ-NF-02 no data migration), the domain model and most business rules are **inherited unchanged** from the current Sequelize models/controllers, not redesigned. This plan documents that inherited model plus the handful of genuinely new decisions the migration itself introduces (session lifetime, RSC data-fetching error semantics) that don't already have an answer in `requirements.md` or the clarifying answers so far.

## Plan Checklist
- [ ] Document the domain model (entities, relationships) — inherited from existing Sequelize associations
- [ ] Document business rules per entity/operation — inherited from existing controllers, restated for traceability
- [ ] Document data flow for the 3 highest-complexity flows: article feed (N+1 fix), auth (cookie session), comment/favorite toggle
- [ ] Resolve the genuinely new decisions below (session lifetime, RSC error handling, feed pagination defaults)
- [ ] Consolidate into `spec/plans/functional-design.md`

## Clarifying Questions

## Question 1
**Business Rules** — The existing backend has no explicit JWT expiration configured (checked in the Atlas deep dive / codebase). Should the new httpOnly cookie session have an explicit expiration?

A) 7-day expiration, matching typical RealWorld reference-implementation conventions and Story 3's "session management" security requirement (SECURITY-12) — sessions expire and require re-login after a week of inactivity

B) No expiration (session cookie, cleared only on browser close or explicit logout) — matches the current system's apparent behavior most closely, but weaker against SECURITY-12's "defined expiration" requirement

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
**Error Handling** — When a Server Component's direct service-layer call throws (e.g. `articleService.getArticleBySlug` finds nothing), should the page use Next.js's `notFound()` (returns a proper 404 page) or render an inline "not found" state within the page component?

A) Use Next.js `notFound()` for missing resources (article/profile not found) — idiomatic App Router pattern, gives a real 404 status and a dedicated `not-found.tsx`

B) Render an inline "not found" message within the page component itself, matching the current SPA's client-side "not found" handling

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
**Data Flow** — The existing feed pagination defaults to `limit=3` (per the Atlas deep dive's N+1 finding). Should the migrated feeds keep this default, or does the N+1 fix change what a reasonable default is?

A) Keep `limit=3` as the default (unchanged) — the N+1 fix (Story 5a) makes the query pattern efficient regardless of page size, so there's no technical reason to change a UX-level default that isn't part of this migration's scope

B) Increase the default limit now that the N+1 fix makes larger pages cheap (e.g. `limit=10`)

C) Other (please describe after [Answer]: tag below)

[Answer]: A
