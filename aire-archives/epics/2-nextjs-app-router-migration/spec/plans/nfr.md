# NFR Requirements & Design: conduit-helix-test Next.js Migration

**Depth**: Light — per `spec/plans/executions.md`, the tech stack is already fixed (Next.js 15,
Sequelize, JavaScript, no Tailwind/Prisma/TypeScript per confirmed requirements), and the security/
performance NFRs are already stated in `spec/plans/requirements.md` (REQ-NF-01 through REQ-NF-07). This
document formalizes them rather than re-deriving from scratch; no new questions were needed since
nothing about NFR scope or tech choice remains open at this point in the cycle.

## Scalability

- **Expected load**: Solo-developer project, no defined concurrent user target (Migration Strategy:
  "self-paced, fast — no hard deadline", no production deploy this cycle). No specific scaling design
  required beyond fixing the known N+1 bottleneck (REQ-F-17).
- **Growth pattern**: Not applicable this cycle — Phase 3 (production deployment, scaling
  infrastructure) is explicitly out of scope.

## Performance

- **Requirement**: Feed/list endpoints must not exhibit N+1 query behavior (REQ-NF-02) — see
  `functional-design.md`'s detailed eager-loading design. Target: O(1) queries relative to article
  count per feed request, verified via Sequelize query logging.
- **Response time**: No hard SLA (solo project, dev environment only this cycle) — informal target
  carried from the Migration Strategy: key pages load in <500ms in development.

## Availability

- Not applicable this cycle — no production deployment, no uptime target, no disaster recovery/
  failover design (Phase 3 out of scope per confirmed requirements REQ-NF-07).

## Security

- **REQ-NF-01**: Auth tokens in `httpOnly` cookies, never `localStorage` — closes the XSS exposure
  identified in `atlas-deep-dive.md`.
- **Tightened input validation** (per `functional-design.md`): email format, password minimum length,
  username format + uniqueness — reduces the attack surface for account-related abuse beyond what the
  current system enforces.
- **Password storage**: bcrypt hashing retained unchanged (`bcryptHash`/`bcryptCompare` ported as-is
  from `backend/helper/bcrypt.js`) — no algorithm change in scope.
- **Security Baseline extension** (always-mandatory per CLAUDE.md): applies automatically during Code
  Generation and Code Review for every story — no separate opt-in needed, already recorded as `Enabled
  = Yes` at workflow start.
- **Property-Based Testing / Resiliency Baseline**: both explicitly declined by the user during
  Requirements Analysis — not applied.

## Tech Stack (confirmed, not re-opened here)

| Layer | Choice | Source of decision |
|---|---|---|
| Framework | Next.js 15 App Router | Migration Strategy (Helix) |
| Language | JavaScript (not TypeScript) | Requirements Analysis Q1 |
| Styling | Existing CSS as-is (no Tailwind) | Requirements Analysis Q2 |
| ORM | Sequelize (retained, not Prisma) | Requirements Analysis Q4 / Migration Strategy's own top recommendation |
| Database | PostgreSQL, unchanged schema | Migration Strategy (non-negotiable constraint) |
| Auth | JWT in httpOnly cookies via Next.js Middleware | Requirements Analysis + Functional Design |
| Testing | Vitest + React Testing Library | Migration Strategy / REQ-F-40 |

## Reliability

- **Error handling**: existing typed error hierarchy reused system-wide (`functional-design.md`) — no
  new error taxonomy, consistent mapping to HTTP status codes.
- **Schema safety**: `sequelize.sync({ alter: true })` removed from the startup path (REQ-F-18) — schema
  changes only via explicit Sequelize CLI migrations, eliminating the current production schema-alter
  risk identified in `atlas-deep-dive.md`.
- **Monitoring/alerting**: not applicable this cycle — no production deployment.

## Maintainability

- Service-layer pattern (Application Design) keeps business logic unit-testable independent of the
  Next.js HTTP layer.
- Vitest + RTL baseline established as new code is written (REQ-F-40, REQ-NF-06) — the current system's
  near-zero coverage is not carried forward as acceptable.
- No dependency on Axios or React Router DOM in `src/` (REQ-NF-05) — reduces the dependency surface
  the solo developer maintains going forward.

## Usability / Accessibility

- Not explicitly required by the Migration Strategy or confirmed requirements — components are ported
  as-is with their existing CSS/behavior; no accessibility audit is in scope for this cycle (consistent
  with the "port existing CSS as-is" decision — no visual/interaction redesign).

## NFR Design Notes (folded in per the light-depth execution plan — no separate nfr-design stage output)

- The httpOnly-cookie + Middleware pattern (security) and the eager-load `include` pattern
  (performance) are the two NFR-driven design patterns that recur across nearly every story — both are
  already fully specified in `functional-design.md` and `application-design.md`, so no additional
  system-level NFR design artifact is needed beyond this document.
