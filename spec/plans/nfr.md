# NFR Requirements & Design — Next.js Modernization

Merges NFR Requirements (tech-stack + targets) and NFR Design (incorporated patterns), per
`common/directory-structure.md`'s single-file convention for this stage pair.

## Tech Stack (already fixed — restated here for traceability)

| Layer | Choice | Source |
|---|---|---|
| Framework | Next.js 15 (App Router) | REQ-F-01, clarifying Q1 |
| Language | Plain JavaScript (ES Modules), no TypeScript | REQ-NF-06, clarifying Q2 |
| ORM | Sequelize 6 (retained, no Prisma) | REQ-NF-06, clarifying Q3 |
| Database | PostgreSQL, in-place retention | REQ-NF-02 |
| Styling | Existing CSS approach, no Tailwind | REQ-NF-06, clarifying Q4 |
| Auth | JWT in httpOnly cookie, Next.js Middleware | REQ-F-03 |
| Deployment | Fly.io | REQ-F-13, clarifying Q5 |
| Testing | Vitest (unit), Playwright (E2E, new pages only) | REQ-F-15, clarifying Q6 |

## Scalability & Performance

- **Scale context**: solo-developer, personal/demo-scale application (~3,500 LOC, no formal SLA) — matches the migration plan's own assessment. No auto-scaling, load-balancing, or multi-region requirements in scope.
- **Performance target**: qualitative sanity check only (Question 2, this stage) — dev response times <500ms, N+1 query-count verification (at most 2-3 queries per feed request, REQ-NF-07) via Sequelize query logging. No formal Core Web Vitals budget is set for this migration; that MAY be revisited in a future cycle if traffic/scale materially changes.
- **Caching**: Server Component `fetch`/data calls use `cache: 'no-store'` for user-specific and mutable data (per the migration plan's own risk mitigation for stale-data caching); no additional caching layer (Redis, CDN edge caching) is introduced.

## Availability

- No formal uptime SLA — Fly.io's standard single-app deployment is sufficient (matches the migration plan's constraints: "no platform/hosting migration in scope" beyond adopting Fly.io itself).
- **Rollback safety** (REQ-NF-05): each phase preserves a working rollback path (Story 1: delete `conduit-next/`; Stories 2-13: old stack remains live; Story 14: git branch + `pg_dump` backup, <5 min rollback).

## Security (Security Baseline — always-mandatory, mapped to this migration's specific surface)

| Rule | Applies to this migration as | Story |
|---|---|---|
| SECURITY-01 (encryption at rest/transit) | PostgreSQL connection over TLS (existing `pg` config, unchanged); Fly.io provides TLS termination | 2, 14 |
| SECURITY-03 (application logging) | Structured server-side logging in Route Handlers/services, no secrets/PII in log output | 3-7 |
| SECURITY-04 (HTTP security headers) | `next.config.js` headers — CSP, HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy — set on all pages | 1 |
| SECURITY-05 (input validation) | Every Route Handler validates request bodies (type/length/format), parameterized Sequelize queries (no raw SQL string concat) | 3-7 |
| SECURITY-08 (access control) | Deny-by-default via `middleware.ts`; object-level authorization on article/comment update-delete (author-only); CORS not applicable (same-origin app); JWT algorithm pinned, no `alg: none`; CSRF — `SameSite=Strict` cookie is the primary defense since state-changing requests are cookie-authenticated | 3, 5, 6 |
| SECURITY-09 (hardening) | Production error responses generic (no stack traces); no default credentials; current Next.js/Node versions | 3-14 |
| SECURITY-10 (supply chain) | `package-lock.json` committed; `npm audit`/`pip-audit`-equivalent (D4 gate) run per this framework's static eval gate | 1 |
| SECURITY-12 (auth/credentials) | bcrypt password hashing (existing, unchanged); session cookie `Secure`+`HttpOnly`+`SameSite`; 7-day expiration (Question 1, Functional Design); session ID (JWT) is CSPRNG-signed | 3 |
| SECURITY-14 (alerting/monitoring) | Fly.io's built-in log stream + metrics dashboard is sufficient for this project's scale (Question 1, this stage) — no external error-tracking service added; structured logs (SECURITY-03) are the human-reviewable record | 14 |
| SECURITY-15 (exception handling) | `lib/errors.js` provides fail-closed error handling across every Route Handler; global handling via Next.js `error.tsx`/`not-found.tsx` for pages | 3, 8 |
| SECURITY-16 (cryptographic standards) | bcrypt (adaptive password hashing, unchanged); JWT signing uses a standard HMAC/RSA algorithm, never `none`; TLS verification never disabled | 3 |

Rules SECURITY-02, 06, 07, 11, 13 are **N/A** for this migration — no load balancer/API gateway/CDN (SECURITY-02), no new IAM/cloud roles (SECURITY-06/07 — Fly.io deployment has no comparable resource-policy surface at this app's scale), no new secure-design-pattern surface beyond what's already covered by SECURITY-08 rate-limiting note below, no XML/deserialization surface introduced (SECURITY-13 — this app parses JSON only).

**Note on SECURITY-11 rate limiting**: not introduced as new scope in this migration (the existing Express app has none either); flagged here as a gap inherited from the current system, not created by the migration, and out of scope for these 17 stories.

## Reliability

- Every external call (DB, in Route Handlers/services) has explicit error handling via `lib/errors.js` (SECURITY-15).
- Resource cleanup: Sequelize's own connection pooling handles this; no manual connection management introduced.

## Maintainability

- Unit test coverage on all new/ported code meets `unitTestCoverageMin` from `tests/.evals/config.json` (REQ-NF-04) — this framework's standard gate, no separate threshold.
- Code organization follows Application Design's component/service boundaries (`spec/plans/application-design.md`) — one service module per resource, consistent naming.

## Usability / Accessibility

- No explicit accessibility requirement beyond what the existing UI already provides (REQ-NF-06 — no UI/styling redesign in scope; components ported as-is).

---

## NFR Design — Patterns & Logical Components

From `spec/spec-generation/nfr-design-questions.md`:

### Category Evaluation
- **Resilience Patterns**: N/A — single DB dependency, no external API/queue/cloud service calls (per `spec/plans/atlas-deep-dive.md`). Sequelize's connection pool + `lib/errors.js` fail-closed handling is sufficient.
- **Scalability Patterns**: N/A — confirmed solo/demo scale, no auto-scaling in scope.
- **Performance Patterns**: N+1 fix via `include` eager loading (Story 5a); uniform `cache: 'no-store'` for ALL data calls, including the tags list (Question 1 — simplest mental model, avoids stale-data risk, tags query is cheap enough not to need caching at this scale).
- **Security Patterns**: full SECURITY-01..16 mapping (above); secrets management — `fly secrets set` for production (`DATABASE_URL`, JWT signing secret), a gitignored `.env.local` for local development only, never committed and never used in production (Question 2).
- **Logical Components**: N/A — no queue, cache layer, or circuit breaker introduced; confirmed by the Atlas deep dive's "no third-party APIs, queues, or cloud services" finding.

### Logical Component Summary

| Component | Pattern |
|---|---|
| `lib/db/index.js` | Sequelize connection singleton (pool managed by Sequelize itself, no custom pooling) |
| `middleware.ts` | Deny-by-default auth gate — runs before every protected Route Handler/page |
| `lib/errors.js` | Fail-closed error boundary — every service/Route Handler error resolves to a typed error, never an unhandled exception |
| Fly.io secrets store | `DATABASE_URL`, JWT signing secret — encrypted at rest via `fly secrets set`, never in source control or a committed `.env` |
| Next.js data cache | `cache: 'no-store'` uniformly on every `fetch`/service call — no caching layer introduced |

No infrastructure diagram is needed beyond this table — the system has exactly one data store (PostgreSQL) and one compute target (the Fly.io-hosted Next.js app), both already covered by `spec/plans/application-design.md`'s component list and this file's Security mapping.
