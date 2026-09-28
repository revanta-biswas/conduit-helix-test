# Requirements Verification Questions

**Context**: The Migration Strategy (`spec/plans/epic-brief.md`) and System Exploration (`spec/plans/atlas-deep-dive.md`) documents from Helix/Atlas are extremely detailed and already settle most architectural decisions (Next.js 15 App Router, Sequelize retained, phased migration, in-place DB). The questions below are the genuine gaps left for AIRE to execute this as a story-driven cycle, plus the two mandatory extension opt-ins.

---

## Question 1: TypeScript Adoption

The migration plan lists TypeScript as "optional but strongly recommended," to be deferred if it slows Phase 1-2.

A) Yes — write all new Next.js code in TypeScript from Phase 0 onward
B) No — keep JavaScript (matches the current codebase, defer any TS migration to post-cutover)
X) Other (please describe after [Answer]: tag below)

[Answer]: B (confirmed by user)

---

## Question 2: Styling Approach

The migration plan lists Tailwind CSS as an "optional styling upgrade."

A) Yes — adopt Tailwind CSS for the new Next.js app
B) No — port the existing CSS/styling approach as-is
X) Other (please describe after [Answer]: tag below)

[Answer]: B (confirmed by user)

---

## Question 3: Cutover Scope for This AIRE Cycle

The migration plan's Phase 3 includes production deployment/DNS cutover and decommissioning `backend/`/`frontend/`. AIRE's own directory conventions place all new application code under `src/` (mapped from the plan's `conduit-next/`).

A) Build through Phase 2 (API + all pages functional in `src/`) in this cycle; treat Phase 3 (production deploy, DNS, decommissioning old dirs) as a manual follow-up outside AIRE once you've validated the app locally
B) Build all 4 phases including Phase 3 decommissioning of `backend/`/`frontend/` as stories in this cycle (no production deploy/DNS — that stays manual regardless)
X) Other (please describe after [Answer]: tag below)

[Answer]: A (confirmed by user)

---

## Question 4: ORM Choice

The plan recommends keeping Sequelize as-is rather than switching to Prisma during the migration.

A) Yes — keep Sequelize, port models as-is (plan's own top recommendation)
B) No — switch to Prisma now
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question: Property-Based Testing Extension
Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints (recommended for projects with business logic, data transformations, serialization, or stateful components)

B) Partial — enforce PBT rules only for pure functions and serialization round-trips (suitable for projects with limited algorithmic complexity)

C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only projects, or thin integration layers with no significant business logic)

X) Other (please describe after [Answer]: tag below)

[Answer]: C (confirmed by user — skip both extensions)

---

## Question: Resiliency Extensions
Should the resiliency baseline be applied to this project?

**What this extension is.** Enabling it applies a set of **directional, design-time best practices** for building resilient systems, derived from the **AWS Well-Architected Framework (Reliability Pillar)** and resilience-review guidance. It steers requirements, design, and code toward fault tolerance, high availability, observability, and recoverability — covering 15 practice areas across business goals, change management, observability, high availability, disaster recovery, and continuous improvement.

**What this extension is NOT.** Enabling it does **not** make your workload production-ready, nor does it certify or guarantee any availability, RTO, or RPO target. It is a **starting point** that scaffolds good resiliency decisions early — it is not a substitute for a formal **AWS Well-Architected Review** of the built system.

Treat the output as a well-grounded **first draft of your resiliency posture** to build on and validate — not a finished, production-certified result.

A) Yes — apply the resiliency baseline as directional best practices and design-time guidance (recommended for business-critical workloads, as an informed starting point that you can validate and harden before go-live)

B) No — skip the resiliency baseline (suitable for PoCs, prototypes, and experimental projects where rapid iteration matters more than reliability)

X) Other (please describe after [Answer]: tag below)

[Answer]: B (confirmed by user — skip resiliency baseline)
