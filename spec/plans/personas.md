# Personas — Next.js Modernization

This migration re-platforms existing behavior rather than adding new user-facing capability, so the
primary "persona" driving most stories is internal (the solo developer executing the migration per
`spec/plans/modernization-plan.md`). End-user personas are carried over unchanged from the existing
Conduit application and are used where a story's acceptance criteria describe end-user-observable
behavior.

## Persona 1: The Solo Developer (Migration Owner)
**Role**: Builds and validates every phase of the migration — architecture, scaffold, ORM, Route Handlers, pages, cutover.
**Goals**: A single unified codebase, one `npm run dev`, lower operational friction, fixed N+1/schema-sync issues, a foundation with test coverage.
**Pain points today**: two servers, two `package.json`s, no SSR, N+1 queries, zero meaningful tests.
**Drives stories**: 1 (Scaffold), 2 (Data Layer), 3 (Auth), 13 (Deploy), 14 (Decommission), 15-17 (test/infra stories).

## Persona 2: Registered Conduit User ("Alex")
**Role**: An authenticated user of the Conduit blogging platform — writes articles, follows other users, favorites articles.
**Goals**: Log in and stay logged in across page loads; create/edit/delete their own articles; see a personalized feed; follow authors; favorite articles they like.
**Pain points today**: session only in `localStorage` (XSS-exposed); N+1 queries slow the feed as content grows.
**Drives stories**: 3 (Auth), 4 (Users API), 5 (Articles CRUD+Feed), 6 (Favorites+Comments), 7 (Profiles+Follow), 9 (Editor page), 10 (Profile page), 11 (Auth pages), 12 (Settings page).

## Persona 3: Anonymous Visitor
**Role**: An unauthenticated visitor browsing public content.
**Goals**: Browse the global feed, filter by tag, read articles and comments, view public profiles, register or log in.
**Pain points today**: no SSR means a slower/less-SEO-friendly first paint.
**Drives stories**: 8 (Home+Article-view pages), 11 (Auth pages — registration entry point).

## Persona Mapping to Stories

| Story | Title | Primary Persona(s) |
|---|---|---|
| 1 | Next.js scaffold setup | Solo Developer |
| 2 | Sequelize data layer port | Solo Developer |
| 3 | Cookie-based auth (Route Handler + Middleware) | Solo Developer, Alex |
| 4 | Users & current-user API | Alex |
| 5 | Article CRUD API | Alex |
| 5a | Article feeds API (N+1 fix) | Alex, Anonymous Visitor |
| 6 | Favorites & comments API | Alex |
| 7 | Profiles & follow API | Alex |
| 8 | Home + Article-view pages | Anonymous Visitor, Alex |
| 9 | Article editor page | Alex |
| 10 | Profile page | Alex, Anonymous Visitor |
| 11 | Auth pages (Login/SignUp) | Anonymous Visitor |
| 12 | Settings page | Alex |
| 13 | Feed filtering re-architecture | Alex, Anonymous Visitor |
| 14 | Production cutover to Fly.io | Solo Developer |
| 15 | Decommission old stack | Solo Developer |
| 16 | Playwright E2E coverage | Solo Developer |
