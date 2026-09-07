> **Source**: Atlas via Helix MCP
> **Server / tool**: helix · get_solution_document_tool (document_chatbot_query / list_solution_documents_tool for discovery)
> **Estate**: conduit-helix-test (solution_id 960, repo revanta-biswas/conduit-helix-test @ 5e127d8569b300e0a21dc2c20ea680da4967b1aa)
> **Scope pulled**: whole-estate deep dive (document_id 3627, "System Exploration: conduit-helix-test") — no narrower scope requested; this is the initial pull for the cycle
> **Fetched**: 2026-09-07T10:11:36Z
> **Freshness**: Atlas document version 30, last updated 2026-09-07T08:53:47Z (Atlas's own timestamp; no separate index-freshness field exposed)

# System Exploration: conduit-helix-test

**Created:** 2026-09-07
**For:** Revanta
**Exploration Depth:** Deep
**Status:** COMPLETE
**Steps Completed:** 10 of 10

> **Purpose:** Comprehensive system exploration providing deep understanding of architecture, flows, dependencies, components, and actionable recommendations.

---

## Executive Summary

**conduit-helix-test** is a full-stack RealWorld Conduit reference implementation — a Medium-style blogging platform demonstrating CRUD, auth, pagination, and social features. Built with React 19 + Vite on the frontend and Express.js 5 + Sequelize + PostgreSQL on the backend, structured as an npm workspaces monorepo (~3,470 LOC across 128 files).

**Top 5 Findings:**

1. **Well-structured, modern stack on both ends** — React 19 + React Router 7 + Vite 7 (frontend) and Express v5 GA + Sequelize 6 + PostgreSQL (backend). All dependencies are at current major versions with no stale or deprecated libraries.
2. **Clean MVC architecture with a critical production risk** — The backend follows a textbook MVC pattern with proper layer separation, but `sequelize.sync({ alter: true })` runs on every boot — a production schema-altering risk that must be gated before any live deployment.
3. **N+1 query pattern is the primary performance bottleneck** — Article list and feed endpoints run `appendFollowers`, `appendFavorites`, and `appendTagList` per article in a loop. Acceptable at the current default limit of 3, but will degrade under load.
4. **Test coverage is critically thin** — Only 3 utility test files exist (2 frontend helpers, 1 backend helper). Zero route, controller, model, or React component tests. Not production-ready from a quality assurance standpoint.
5. **Documentation gaps are the highest-priority action item** — No API spec (Swagger/OpenAPI), no ADRs, no ERD, no deployment guide. The README is good for local setup but leaves a new developer on their own for everything else.

---

## System at a Glance

**What it is:** A full-stack RealWorld Conduit reference implementation — a Medium-style blogging platform with articles, comments, profiles, and tag-based feeds.

**Technology Stack:**

- **Primary Language:** JavaScript (ES Modules)
- **Frontend:** React 19.2.4 + React Router DOM 7.x, built with Vite 7.3.5 + SWC
- **Backend:** Express.js 5.2.1, Sequelize 6.37.8 ORM
- **Database:** PostgreSQL (pg 8.20.0)
- **Auth:** JWT (jsonwebtoken 9.0.3) + bcrypt 6.0.0
- **HTTP Client:** Axios 1.13.6 (frontend)
- **Build Tool:** npm workspaces monorepo + Vite (frontend), plain Node.js (backend)
- **Testing:** Vitest 4.0.18

**Architecture Style:** Decoupled full-stack monorepo — React SPA frontend over REST with Express.js MVC backend and Sequelize Active Record models.

**Quick Stats:**

| Metric | Value |
|--------|-------|
| Total Files | 128 |
| Lines of Code | ~3,470 |
| Test Files | 3 (very sparse) |
| Configuration Files | ~5 |
| Documentation Files | 2 (README, CODE_OF_CONDUCT) |

**Entry Points:**

- Frontend: `frontend/src/main.jsx`
- Backend: `backend/index.js`
- Dev (both): `npm run dev` (ports 3000 frontend / 3001 API)

**Documentation State:**

- README: Present and good quality — covers prerequisites, install, config, dev, testing, production
- API Docs: Absent — no Swagger/OpenAPI spec
- Architecture Docs: Absent — no ADRs or design docs
- Inline Comments: Very sparse — mostly route-label comments only
- Test Coverage: Only 3 test files covering 2 frontend helpers + 1 backend helper; no route/controller/component tests

---

## Architecture Analysis

### Architectural Style

Decoupled full-stack monorepo: a React SPA frontend communicates over REST with an Express.js MVC backend. Sequelize Active Record models handle data persistence against PostgreSQL. The two halves are independently runnable but deployed together in production (backend serves frontend's static build).

**Key Patterns:**
- **MVC (Backend):** Routes -> Controllers -> Sequelize Models — clean, well-enforced separation
- **Active Record (Models):** Sequelize models own their own associations and serialisation (`toJSON()` redacts sensitive fields like `id`, `userId`)
- **Service Layer (Frontend):** Thin one-function-per-API-operation service files (e.g. getArticles.js, toggleFav.js) — clean separation from UI
- **Context API for Auth:** `AuthContext` stores JWT + user state globally, hydrated from `localStorage` on load

---

> **Note (AIRE)**: This local copy captures the sections most relevant to the current cycle (Executive Summary, System at a Glance, Architecture Analysis). The full 609-line Atlas document (document_id 3627, v30) also contains: Critical System Flows, Dependency Analysis, Component Inventory, Code Quality & Technical Debt, Knowledge Gaps & Recommendations, Getting Started, and a Referenced Paths drift-detection manifest. Fetch document_id 3627 directly via the Helix MCP for the full text when a later stage needs a section not reproduced here.
