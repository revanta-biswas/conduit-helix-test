# Story Generation Plan: Next.js Migration (Phases 0-2)

## Approach

**Feature-Based** breakdown, bundled by resource group / page cluster rather than fully SPIDR-split
per CRUD verb, per explicit user override (target count "under 10").

**team_size**: 2 (fixed default, never asked)
**story_creation_mode**: all-at-once (fixed default, never asked)
**target_story_count**: 9 (user override — see trade-off note below)

## Story Count — Question & Answer

```
 How many user stories should I create for this work?

    Recommended: 22 stories  (suggested range: 18-25)

   Why 22:
   - 40 functional requirements (REQ-F-01..40) SPIDR-sliced by resource group/CRUD verb across
     Setup, API layer (5 resource groups), Frontend (6 pages + cross-cutting concerns), and Testing
   - Keeps ≥ 2 (team_size) stories runnable in parallel (API track vs Frontend track)
   - Each story stays within the Step 1.5 sizing ceilings (≤5 ACs, one layer, one scenario class)

   Reply with a number to override, or "ok"/"use recommended" to accept 22.
[Answer]: make it under 10
```

**Trade-off flagged and accepted**: fewer than 10 stories means bundling multiple resource groups /
pages / CRUD verbs into single stories rather than SPIDR-splitting each one individually. Some stories
below will carry more than 5 ACs and span more than one scenario class (e.g. full CRUD + list/feed in
one story) to stay under the requested ceiling. This is a deliberate, user-directed exception to the
Step 1.5 hard sizing ceilings — logged here and in `runtime-artifacts/audit.md` rather than silently
overridden. Parallelism is still preserved: stories 1-2 (Setup) block everything; stories 3-6 (API
layer) can proceed in parallel with each other once Setup lands; stories 7-9 (Frontend) depend on the
API stories they consume.

## Story Plan Checklist

- [x] Step 1: team_size fixed at 2
- [x] Step 1.5: SPIDR slicing rules applied conceptually, then deliberately coarsened per user's
      "under 10" override (bundling CRUD verbs/pages by resource group instead of splitting each)
- [x] Step 2-11: Story plan created (this document)
- [x] Step 12: Plan announced (auto-approved, no gate)

## Story Breakdown (9 stories)

| # | Story | Bundles | Covers (REQ-IDs) | Layer(s) |
|---|-------|---------|---|---|
| 1.1 | Next.js Foundation & DB Layer | Scaffold, Sequelize model port, DB singleton, env config | REQ-F-01,02,03,04,05 | Infra + Data |
| 1.2 | Auth: Register, Login & httpOnly Cookie Session | Auth Route Handlers + Middleware + error/helper port + N+1/sync fixes shared setup | REQ-F-10,15,16,18; REQ-NF-01,03 | API |
| 1.3 | User Profile API (current user + public profiles + follow) | GET/PUT /api/user, GET /api/profiles/:username, follow/unfollow toggle | REQ-F-11,13 | API |
| 1.4 | Articles API: CRUD, Feed & Tags | Full article CRUD, global/personal feed, N+1 fix via eager loading, tags endpoint | REQ-F-12,14,17; REQ-NF-02,04 | API |
| 1.5 | Favorites & Comments API | Favorite/unfavorite toggle, comment CRUD | REQ-F-12 (favorites/comments slice) | API |
| 1.6 | Auth Pages & Session (Login/Register/Settings) | Login, Register, Settings pages as Client Components; cookie-based session replacing AuthContext | REQ-F-24,25,28 | Frontend |
| 1.7 | Home & Article Pages (RSC) | Home feed page, Article view page as Server Components; FeedContext → URL params | REQ-F-20,21,29 | Frontend |
| 1.8 | Article Editor & Profile Page | Create/edit article Client Component, Profile page Server Component | REQ-F-22,23 | Frontend |
| 1.9 | Shared UI Components, Service Layer Elimination & Test Baseline | Port ~20 components, remove Axios/React Router, Vitest+RTL baseline | REQ-F-26,27,30,40; REQ-NF-05,06,07 | Frontend + Testing |

**Personas**: Solo Developer (builds and validates every story — the only persona per the Migration
Strategy's "solo developer, all roles" constraint); End User / Reader (consumes Conduit — registers,
browses, follows, favorites); Author (creates/edits articles, comments).

## Dependency Sketch (refined in the Dependency Graph stage)

- 1.1 blocks everything (DB layer + scaffold).
- 1.2 (auth) blocks 1.3, 1.4, 1.5 (all need `req.loggedUser` / middleware) and blocks 1.6 (login page needs the auth API).
- 1.3, 1.4, 1.5 are mutually independent once 1.2 lands (parallelizable — the ≥2 parallel-story rule).
- 1.6 depends on 1.2 (auth API). 1.7 depends on 1.4 (articles/feed API) + 1.3 (profile data shown in feed). 1.8 depends on 1.4 (articles API) + 1.3 (profile API).
- 1.9 depends on 1.6, 1.7, 1.8 (components/services it eliminates are used by all three) — effectively last.

(Exact `requires` fields are computed and finalized in the Dependency Graph stage per its own rules —
this is a planning-time sketch only.)
