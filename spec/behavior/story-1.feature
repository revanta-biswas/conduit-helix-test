Feature: Next.js application scaffold

  Background:
    Given the repository root contains a root "package.json" with an npm "workspaces" array
    And the existing "backend" and "frontend" workspace members are present

  @AC-1
  Scenario: conduit-next is a registered npm workspace member running Next.js 15 App Router
    When the root "package.json" "workspaces" array is inspected
    Then it includes "conduit-next"
    And "conduit-next/package.json" declares a "next" dependency on major version 15
    And "conduit-next/app" exists as the App Router entry directory

  @AC-2
  Scenario: The conduit-next dev server starts without errors on a non-colliding port
    When "npm run dev -w conduit-next" is started
    Then the process starts without throwing or exiting non-zero
    And it listens on port 3002
    And an HTTP request to "http://localhost:3002/" returns a successful response
    And ports 3000 and 3001 remain owned by "frontend" and "backend" respectively (no collision)

  @AC-3
  Scenario: ESLint and Prettier are configured for conduit-next in plain JavaScript
    When "npm run lint -w conduit-next" is executed
    Then it runs to completion using "conduit-next/eslint.config.mjs"
    And no "tsconfig.json" exists anywhere under "conduit-next/"
    And a Prettier configuration is present and used by "conduit-next"'s format script

  @AC-4
  Scenario: backend and frontend are unmodified by this story
    When "git diff --stat" is computed between the epic branch and this story's branch
    Then no changed path starts with "backend/"
    And no changed path starts with "frontend/"
