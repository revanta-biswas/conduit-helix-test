# Code Generation Plan — Story 1.1: Next.js Foundation & Database Layer

**Tracker**: [#19](https://github.com/revanta-biswas/conduit-helix-test/issues/19) | **Epic**: Milestone #2 | **Branch**: story/1.1-nextjs-foundation-db-layer
**Covers**: REQ-F-01, REQ-F-02, REQ-F-03, REQ-F-04, REQ-F-05

**Grounding**: story ACs (stories.md #1.1), requirements.md (REQ-F-01..05), architecture.md
(Section 3 Layering — DB Layer sole owner of Sequelize; ARCH-05 no unsafe sync), application-design.md
(DB Layer component), functional-design.md (domain model unchanged), atlas-deep-dive.md + the actual
backend/models/*.js (read directly, ported faithfully). No design references registered.

**Design reference grounding (DR-5)**: `## Design References` is empty this cycle → `Design reference:
none covers this component — built from ACs only` applies to every file below.

## Plan Steps

- [x] **S1 — Next.js scaffold under src/** (AC-1 → REQ-F-01, REQ-F-02)
  - `src/package.json`? No — this is a workspace addition; the Next.js app lives at `src/` with its own
    `next.config.js`, `package.json` for `src` is NOT created (kept in the root workspace). Instead add
    Next.js + React as root/`src` dependencies and create `src/app/layout.js` + `src/app/page.js` as a
    minimal bootable App Router root.
  - `src/app/layout.js` — root layout (required by App Router).
  - `src/app/page.js` — minimal home placeholder (real Home page is Story 1.7).
  - `next.config.js` at repo root (or `src/`) configuring the app dir.
  - `.prettierrc` (recommended defaults) + confirm eslint.config.js covers `src/` (already bootstrapped).
  - 🔴 Do NOT touch backend/ or frontend/ (AC-1).
- [x] **S2 — Port Sequelize models** (AC-2 → REQ-F-03)
  - `src/lib/db/models/Article.js`, `User.js`, `Tag.js`, `Comment.js` — ported VERBATIM in logic from
    `backend/models/*.js` (same associations, same toJSON redaction), only the module wrapper adapted to
    the new index loader.
- [x] **S3 — DB config from env** (AC-4 → REQ-F-04)
  - `src/lib/db/config.js` — reads `DATABASE_URL` OR `DB_*`/`DEV_DB_*` env vars (superset of the current
    config so existing `.env` keys keep working). No hardcoded credentials (ARCH-05-adjacent; SEC-04).
- [x] **S4 — Sequelize singleton index** (AC-3, AC-5 → REQ-F-03, REQ-F-05)
  - `src/lib/db/index.js` — singleton pattern (`globalThis.__sequelize ??= new Sequelize(...)`) so
    Next.js dev hot-reload does not spawn duplicate pools; loads all 4 models, runs `associate()`,
    exports `{ sequelize, Sequelize, User, Article, Tag, Comment }`. 🔴 Calls NOTHING that alters schema —
    no `sequelize.sync({ alter: true })` (ARCH-05). Provides an `authenticate()` passthrough for boot.
  - `.env.local.example` — documents required env vars (no secrets).
- [x] **S5 — Unit tests (Step 6, SH-LOOP-1, ≥90% on new code)** (AC-2, AC-3 → REQ-F-05, REQ-NF-06)
  - `tests/unit/lib/db/models.test.js` — assert all 4 models defined, associations present (AC-2),
    toJSON redaction works.
  - `tests/unit/lib/db/singleton.test.js` — assert repeated import returns the same instance (AC-3).
  - `tests/unit/lib/db/config.test.js` — assert config reads env, no hardcoded creds (AC-4).
  - Tests use an in-memory/SQLite or mocked Sequelize where a real PostgreSQL is unavailable, so they run
    without external infra (AC-5's live-DB assertion is covered by the ve manual test plan + the model
    load test here; a real-DB connect is environment-dependent and not gated in unit tests).
- [x] **S6 — Gherkin step definitions (Step 6.1, B1/B2)** 
  - `tests/behavior/steps/story-1.1_steps.js` (or the cucumber-js equivalent) binding the 5 scenarios in
    `spec/behavior/story-1.1.feature` to the public DB-layer surface.

## REQ/AC Trace Self-Check

| Plan step | ACs | REQ-IDs |
|---|---|---|
| S1 | AC-1 | REQ-F-01, REQ-F-02 |
| S2 | AC-2 | REQ-F-03 |
| S3 | AC-4 | REQ-F-04 |
| S4 | AC-3, AC-5 | REQ-F-03, REQ-F-05 |
| S5 | AC-2,3,4 | REQ-F-05, REQ-NF-06 |
| S6 | AC-1..5 | (behaviour contract) |

Every covered REQ-ID (01-05) appears in ≥1 step; every AC (1-5) appears in ≥1 step. ✅ Trace complete.

## Notes / Deviations
- **No `src/package.json`**: the migration plan's `conduit-next/` implied a separate package, but AIRE's
  directory rule places new code under `src/` within the existing repo. Next.js deps are added to the
  root workspace; `next.config.js` points at `src/app`. This is a scope-neutral adaptation, recorded here.
- **AC-5 live DB**: a real PostgreSQL connection is environment-dependent (no DB is guaranteed in this
  session). The unit tests assert model loading + associations against a lightweight/mocked Sequelize;
  the genuine "boots and connects to the real DB" check is in ve's manual test plan (`/ve-implement 1.1`)
  and verifiable by the developer running `next dev` locally. This is stated plainly, not silently
  dropped.
