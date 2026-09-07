# Story Generation Plan — Next.js Modernization

**Role**: Product owner slicing the approved requirements (`spec/plans/requirements.md`) into small,
single-purpose, independently reviewable stories for the Next.js migration.

`team_size: 2` (fixed default, not asked). `story_creation_mode: all-at-once` (fixed default, not asked).

## SPIDR Slicing Log (Step 1.5 — applied before this plan was written)

| Requirement(s) | Axis applied | Resulting story boundary |
|---|---|---|
| REQ-F-01 | Steps | Scaffold story — must precede everything else |
| REQ-F-02 | Steps | Data-layer port — precedes all API stories |
| REQ-F-03, REQ-F-08 (auth slice), REQ-NF-03 | Interfaces | Auth is its own entry surface; built and validated first per the migration plan's own top risk |
| REQ-F-04, REQ-F-08 (users slice) | Interfaces | Users/current-user API — depends on auth |
| REQ-F-05, REQ-NF-01 (articles slice), REQ-NF-07 | CRUD | Split further: Articles CRUD+feed (create/read/update/delete/feed) vs Favorites+Comments (thick sub-resources, each with their own create/delete verbs) |
| REQ-F-06, REQ-F-07 | Interfaces | Profiles+Follow and Tags combined — Tags is a single thin read-only endpoint with no independent logic, folded in as a sibling rather than its own story |
| REQ-F-09, REQ-F-10, REQ-F-11 (page slices) | Steps + CRUD | Read-heavy pages (Home+Article view) separated from the write-heavy Editor (Create/Update distinct architectural pattern — Client Component form vs RSC), separated from Profile, from Auth pages (Login/SignUp), from Settings — 5 page stories, each porting its own components + eliminating its own Axios calls |
| REQ-F-12 (Feed Context slice) | Rules | Feed filtering (global/personal/tag) is a distinct business rule from page rendering — its own story so the URL-search-param re-architecture is independently reviewable |
| REQ-F-13 | Steps | Cutover/deploy — depends on all API + page stories |
| REQ-F-14 | Steps | Decommission — last story, depends on cutover |
| REQ-F-15 | Interfaces | Playwright E2E — new-pages-only per clarifying answer Q6; depends on the page stories it covers |

All NFRs (REQ-NF-02, 04, 05, 06) are cross-cutting acceptance criteria applied to the relevant stories above rather than standalone stories (they describe qualities of the work, not units of user-visible behavior).

## Story Count

 How many user stories should I create for this work?

   Recommended: 16 stories (suggested range: 14-18)

   Why 16:
   - 15 functional requirements SPIDR-sliced into single-purpose stories — the Articles capability (REQ-F-05) splits into 2 (CRUD+feed vs favorites+comments, both distinct CRUD sub-resources) and the page-migration capability (REQ-F-09/10/11) splits into 5 (read pages, editor, profile, auth pages, settings — each a distinct architectural pattern per the Steps/CRUD axes); Tags (REQ-F-07) folds into the Profiles+Follow story as a thin sibling read-only endpoint rather than its own story, since it has no independent logic to review
   - Yields well over team_size (2) independently workable stories once the auth and data-layer foundation stories are merged — Users API, Profiles+Tags, and most page stories can proceed in parallel
   - Each story stays within the Step 1.5 sizing ceilings (<=5 ACs, one new architectural layer, one scenario class) — e.g. Articles CRUD is kept separate from Favorites+Comments specifically to avoid bundling two scenario classes into one story

   Reply with a number to override, or "ok"/"use recommended" to accept 16.
[Answer]: ok

## Story Breakdown Approach

**Feature-Based**, following the migration plan's own phase structure (Phase 0 Setup -> Phase 1 API -> Phase 2 Frontend -> Phase 3 Cutover) — this is not a User Journey or Persona breakdown because the work is a like-for-like re-platform of existing behavior, not new user-facing capability. Feature/phase boundaries map directly onto the Dependency Graph's `requires` edges (data layer before API, API before pages, everything before cutover).

## Plan Checklist

- [x] Generate `stories.md` with 16 stories following INVEST criteria, beginning with the Parent Epic header line
- [x] Every story carries a `**Covers**: REQ-F-xx[, REQ-NF-yy]` line
- [x] Generate `personas.md`
- [x] Map personas to stories
- [x] Requirements Coverage Matrix — every REQ-ID in requirements.md fully covered
- [x] Story granularity check — every story within Step 1.5 hard sizing ceilings
