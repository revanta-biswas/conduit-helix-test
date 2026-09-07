# Infrastructure Design Plan — Next.js Modernization

## Context Analyzed
- `spec/plans/functional-design.md`, `spec/plans/nfr.md` read.
- Deployment target already fixed: Fly.io (REQ-F-13, clarifying answer Q5).

## Category Evaluation

- **Deployment Environment**: Fly.io — already decided, no question needed.
- **Compute Infrastructure**: a single Fly.io app (one Next.js process) — no multi-service split; question below on sizing.
- **Storage Infrastructure**: PostgreSQL, in-place retention (REQ-NF-02) — already decided, no new storage decision needed. Question below only on whether the DB itself is Fly Postgres or an existing external instance.
- **Messaging Infrastructure**: N/A — no queues/events anywhere in this system (confirmed by the Atlas deep dive).
- **Networking Infrastructure**: N/A — Fly.io provides TLS termination and routing for a single app; no load balancer/API gateway/CDN configuration is introduced by this migration.
- **Monitoring Infrastructure**: already decided in NFR Design — Fly.io's built-in metrics/logs, no external service.
- **Shared Infrastructure**: N/A — single app, single database, no multi-tenancy.

## Clarifying Questions

## Question 1
**Compute Infrastructure** — What Fly.io machine size should `conduit-next/` run on?

A) Fly.io's smallest shared-CPU machine (`shared-cpu-1x`, 256MB-1GB RAM) — matches the app's small scale (~3,500 LOC, solo/demo traffic), lowest cost, can be resized later if traffic grows

B) A larger dedicated-CPU machine, sized for headroom beyond current traffic expectations

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
**Storage Infrastructure** — Is the production PostgreSQL database an existing external instance (e.g. already running somewhere, per REQ-NF-02's "no data movement"), or should this migration provision a new Fly Postgres instance?

A) Existing external PostgreSQL instance — REQ-NF-02 says the database is retained in-place; this migration only points `conduit-next/`'s `DATABASE_URL` at whatever instance the current `backend/` already connects to, no new DB is provisioned

B) Provision a new Fly Postgres instance as part of Story 14 (cutover) — implies a one-time data migration from the current instance, which would need to be reconciled with REQ-NF-02

C) Other (please describe after [Answer]: tag below)

[Answer]: A
