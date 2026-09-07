# Infrastructure Design — Next.js Modernization

## Deployment Environment

- **Provider**: Fly.io (REQ-F-13, clarifying answer Q5 — matches the existing demo's hosting).
- **Deployment unit**: a single Fly.io app running the built `conduit-next/` Next.js process (`next build && next start`, per Story 14 AC-1).
- **Region**: single region (no multi-region requirement at this scale) — deployed to whichever region the existing demo app uses, or Fly.io's default if none is recorded.

## Compute Infrastructure

- **Machine size**: `shared-cpu-1x` (256MB-1GB RAM), Fly.io's smallest shared-CPU tier — matches the confirmed solo/demo scale (Question 1). Resizable later without a redesign if traffic grows; not a decision this migration needs to over-provision for.
- **Process count**: 1 Next.js process (no separate frontend/backend processes — this is the entire point of the migration, REQ-F-01/F-13).
- **Auto-stop/auto-start**: Fly.io's standard auto-stop-machines behavior is acceptable at this scale (no requirement for always-on compute beyond what Fly.io's defaults provide).

## Storage Infrastructure

- **Database**: the existing external PostgreSQL instance the current `backend/` already connects to (Question 2) — REQ-NF-02 mandates in-place retention, so no new Fly Postgres instance is provisioned. `conduit-next/`'s `DATABASE_URL` (via `fly secrets set`, per NFR Design) points at this same instance.
- **No object storage / file storage** is introduced — the existing system has none (no image uploads beyond profile `image` URLs, which are stored as plain string fields, unchanged).

## Messaging Infrastructure

**N/A** — no queues, event buses, or async processing anywhere in this system, confirmed by `spec/plans/atlas-deep-dive.md` ("no third-party APIs, queues, or cloud services").

## Networking Infrastructure

**N/A beyond Fly.io's own defaults** — Fly.io terminates TLS and routes traffic to the single app; no separate load balancer, API gateway, or CDN configuration is introduced by this migration. `next.config.js` headers (CSP, HSTS, etc. — SECURITY-04, already specified in `nfr.md`) are the application-level networking/security surface.

## Monitoring Infrastructure

Already decided in NFR Design: Fly.io's built-in metrics/log stream is sufficient at this scale; no external error-tracking service is added.

## Shared Infrastructure

**N/A** — single app, single database, no multi-tenancy, no infrastructure shared with any other project.

## Deployment Diagram (text — per content-validation.md, no complex Mermaid needed for this small a topology)

```
                    +-------------------------+
  HTTPS requests --> |  Fly.io (shared-cpu-1x) |
                    |  conduit-next/ (Next.js)|
                    +------------+------------+
                                 |
                                 | DATABASE_URL (fly secrets)
                                 v
                    +-------------------------+
                    |  Existing PostgreSQL     |
                    |  instance (unchanged)    |
                    +-------------------------+
```

Text alternative: One Fly.io app (`shared-cpu-1x` machine) runs the unified `conduit-next/` Next.js process, handling both page rendering and API Route Handlers. It connects to the same existing external PostgreSQL instance the current `backend/` already uses, via `DATABASE_URL` set through Fly.io's encrypted secrets store. No other infrastructure component exists in this deployment.
