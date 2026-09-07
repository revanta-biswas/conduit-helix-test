# aire State Tracking

## Project Information
- **Project Type**: Brownfield
- **Start Date**: 2026-09-07T10:11:36Z
- **Current Stage**: PLANNING - Requirements Analysis

## Workspace State
- **Existing Code**: Yes
- **Programming Languages**: JavaScript (ES Modules) — React 19 (frontend), Express.js 5 (backend)
- **Build System**: npm workspaces monorepo (Vite for frontend, plain Node.js for backend)
- **Project Structure**: Decoupled full-stack monorepo (RealWorld Conduit reference app)
- **Workspace Root**: /Users/revanta.biswas/Desktop/conduit-helix-test
- **Reverse Engineering Needed**: No — satisfied by Atlas deep dive (see below)

## Code Location Rules
- **Application Code**: `backend/` and `frontend/` (see `## Code Root` below)
- **Documentation**: spec/ only
- **Structure patterns**: See code-generation.md Critical Rules

## Code Root
- **Type**: monorepo
- **Path(s)**: backend, frontend (declared in root `package.json` `workspaces`)
- **Recorded**: 2026-09-07T10:11:36Z
- **Note**: existing tree left in place; new application code for this cycle follows the migration plan's target layout (`conduit-next/`), created fresh under this monorepo

## Existing-System Context
- **Workspace type**: brownfield | migration
- **Helix MCP**: connected
- **Source**: atlas
- **Components in scope**: whole estate (backend routes/controllers/models, frontend pages/components/services/contexts)
- **Atlas deep dive doc**: spec/plans/atlas-deep-dive.md
- **Modernization/Migration plan**: spec/plans/modernization-plan.md (Atlas document_id 3638, "Migration Strategy: conduit-helix-test")
- **Recorded**: 2026-09-07T10:11:36Z

## Helix MCP Binding
- **Server**: helix
- **Docs tool(s)**: get_solution_document_tool, list_solution_documents_tool — fetches solution documents (deep dive, migration strategy) by ID
- **Graph/Search tool(s)**: document_chatbot_query, codebase_agent_query, codebase_cypher_query, graph_change_impact — targeted inline answers on demand
- **Estate / workspace id**: solution_id 960 (conduit-helix-test)
- **Resolved**: 2026-09-07T10:11:36Z

## Tracker
- Type: GITHUB
- Parent Epic: none
- Epic URL: —
- Project Key / Repo / Org: revanta-biswas/conduit-helix-test

## Branching
- Base Branch: main
- Epic Branch: epic/nextjs-modernization
- Epic PR: (not raised — raised manually at cycle end via pr-generator)

## Context Project
- **Existing Knowledge**: No
- **Existing Knowledge Path(s)**: —
- **New References**: No
- **New Reference Path(s)**: —

## Stage Progress
- Workspace Detection: Complete
- Reverse Engineering: Skipped (satisfied by Atlas deep dive)
- Requirements Analysis: Complete (approved 2026-09-07T10:11:36Z)
