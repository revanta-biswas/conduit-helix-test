# NFR Requirements Plan — Next.js Modernization

## Context Analyzed
- `spec/plans/functional-design.md`, `spec/plans/requirements.md` (REQ-NF-01..07 already fix most NFR decisions).
- `spec/plans/modernization-plan.md` — small solo project (~3,500 LOC), no formal load-testing scope, Fly.io target already confirmed (clarifying answer Q5).
- Security Baseline extension (`extensions/security/baseline/security-baseline.md`) is always-mandatory — SECURITY-01 through 16 apply regardless of this stage's answers.

**Framing**: tech stack is already fully decided (Next.js 15, plain JavaScript, Sequelize, PostgreSQL, Fly.io — all fixed by the requirements/clarifying answers). This stage's job is mainly to state the NFR targets explicitly and flag the few genuinely open operational questions.

## Plan Checklist
- [ ] Document scalability/performance targets (small-scale, solo-developer context)
- [ ] Document availability expectations (no formal SLA — personal/demo-scale app)
- [ ] Document security requirements (Security Baseline mapping to this migration's specific surface: auth, Route Handlers)
- [ ] Resolve the 2 open questions below
- [ ] Consolidate into `spec/plans/nfr.md`

## Clarifying Questions

## Question 1
**Reliability / Monitoring** — SECURITY-14 (always-mandatory) calls for alerting on security events and a monitoring dashboard. Fly.io has built-in metrics; should this migration wire up anything beyond Fly.io's default dashboard (e.g. an external error-tracking service), or is Fly.io's built-in observability sufficient for this project's scale?

A) Fly.io's built-in metrics/logs are sufficient — no external error-tracking service (e.g. Sentry) added in this migration; SECURITY-14's alerting requirement is satisfied by structured server-side logging (SECURITY-03) that a human can review in Fly.io's log stream, not automated alert rules (N/A for a solo-developer, non-production-SLA app)

B) Add an external error-tracking service (e.g. Sentry) as part of this migration's scope

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
**Performance target** — The migration plan sets no formal load-testing target (matches this app's solo/demo scale). Should this migration set an explicit page-load performance budget (e.g. Core Web Vitals thresholds), or rely on the qualitative "<500ms dev response time" sanity check already in the migration plan?

A) Rely on the existing qualitative sanity check (dev response time <500ms, N+1 query-count verification) — no formal Core Web Vitals budget; this is consistent with REQ-NF-07's own scope and the migration plan's stated "formal load testing is not required" for this app's scale

B) Add explicit Core Web Vitals budgets (LCP/FID/CLS thresholds) as a new NFR for this migration

C) Other (please describe after [Answer]: tag below)

[Answer]: A
