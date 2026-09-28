Feature: Shared UI Components, Service-Layer Elimination & Test Baseline
  As a solo developer
  I want the UI components ported, the Axios/React-Router dependency removed, and a test baseline
  So that the migration is complete, maintainable, and has real test coverage

  # Story 1.9 — Covers REQ-F-26, REQ-F-27, REQ-F-30, REQ-F-40, REQ-NF-05, REQ-NF-06, REQ-NF-07

  @AC-2
  Scenario: No source file under src/ imports Axios
    When the src tree is scanned for imports
    Then no file imports "axios"

  @AC-2
  Scenario: No source file under src/ imports react-router-dom
    When the src tree is scanned for imports
    Then no file imports "react-router-dom"

  @AC-4
  Scenario: No TypeScript files were introduced
    When the src tree is scanned for file extensions
    Then there are no ".ts" or ".tsx" files

  @AC-1
  Scenario: The shared UI components are present in src/components
    When the components directory is listed
    Then it contains "Navbar", "Footer", "ArticlesPreview" and "CommentList"

  @AC-1
  Scenario: The ported CSS is present and imported by the root layout
    When the app styling is checked
    Then src/app/styles.css exists
    And the root layout imports the styles
