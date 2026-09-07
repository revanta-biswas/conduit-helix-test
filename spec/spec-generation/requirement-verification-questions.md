# Requirements Clarification Questions — Next.js Modernization

The migration plan pulled from Atlas (`spec/plans/modernization-plan.md`) is detailed and largely
answers scope/approach/architecture questions on its own. The items below are the genuine open
decisions it leaves to you before requirements.md and the story breakdown can be written.

## Question 1
Where should the new Next.js application live in this repository?

A) New `conduit-next/` package alongside `backend/` and `frontend/`, added to npm workspaces — matches the plan's own interim-state layout exactly, old stack untouched until cutover

B) Replace `frontend/` in place now (rename to a Next.js app) and point Route Handlers at the existing `backend/` until Phase 3

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
The plan recommends TypeScript as "strongly recommended, optional." Should this migration adopt TypeScript?

A) Yes — write all new Next.js code (Route Handlers, components, models) in TypeScript from Phase 0

B) No — keep JavaScript (ES Modules) throughout, matching the current codebase, to reduce migration risk

C) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 3
The plan says the ORM choice is Sequelize (retained) OR Prisma (optional upgrade, evaluate post-migration). Confirm:

A) Sequelize only for this migration — no Prisma evaluation in scope

B) Include a Prisma evaluation/spike as part of this migration's scope

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
Styling: the plan lists Tailwind CSS as "optional styling upgrade." Should this migration include a styling upgrade, or keep the existing CSS approach?

A) Keep existing CSS/styling approach as-is, ported over unchanged

B) Adopt Tailwind CSS during this migration

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5
Deployment target for Phase 3 cutover — the plan mentions "Vercel, Railway, Fly.io, or existing host" without picking one. Which should the stories target?

A) Vercel

B) Fly.io (README's existing demo link points here)

C) Railway

D) Other (please describe after [Answer]: tag below)

[Answer]: D fly.io, matching existing demo

## Question 6
Should end-to-end/UI test automation (Playwright — mandatory per this framework's extensions) target the NEW Next.js pages only, or also add regression coverage of the OLD stack while it's still live during Phases 0-2?

A) New Next.js pages only — the old stack is being decommissioned, no point investing in its test coverage

B) Both — add baseline Playwright coverage of the current SPA first, to have a regression safety net during migration

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 7
The plan's Phase 3 "Cutover" includes archiving/removing `backend/` and `frontend/` directories. Should that removal happen as part of this epic's stories, or be left as a manual follow-up after this epic's PRs merge?

A) Include removal of `backend/` and `frontend/` as the final story of this epic

B) Leave `backend/`/`frontend/` in place; removal is a manual follow-up outside this epic

C) Other (please describe after [Answer]: tag below)

[Answer]: A
