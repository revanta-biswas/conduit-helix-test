Feature: Next.js Foundation & Database Layer
  As a solo developer
  I want a working Next.js 15 App Router scaffold with the existing database layer ported over
  So that I have a foundation to build the API and pages on, without touching the live backend/frontend system

  # Story 1.1 — Covers REQ-F-01, REQ-F-02, REQ-F-03, REQ-F-04, REQ-F-05
  # Note: this story is foundational infrastructure. Its observable behaviour is exercised
  # through the ported DB layer's model definitions and associations, and the app's ability to
  # boot and connect. Scenarios bind to the PUBLIC surface of src/lib/db (the exported models,
  # sequelize instance, and config), never to internals.

  @AC-1
  Scenario: Next.js App Router app scaffold exists alongside the untouched legacy workspaces
    Given the repository has an existing backend/ and frontend/ workspace
    When the Next.js application is scaffolded under src/
    Then the src/ directory contains a Next.js 15 App Router structure
    And the existing backend/ and frontend/ directories are unchanged
    And ESLint and Prettier are configured for the src/ app in JavaScript

  @AC-2
  Scenario: All four Sequelize models are ported with their associations intact
    Given the Sequelize models from backend/models are ported into src/lib/db/models
    When the models are loaded
    Then the models Article, User, Tag, and Comment are all defined
    And the User model has the Favorites, followers, and following associations
    And the Article model has the tagList, author, and comments associations

  @AC-3
  Scenario: The Sequelize instance is a singleton that survives repeated loads
    Given the DB layer initialises Sequelize via a singleton pattern
    When the DB layer module is loaded more than once in the same process
    Then the same Sequelize instance is returned each time
    And no additional connection pool is created on the second load

  @AC-4
  Scenario: Database configuration is read from environment variables
    Given a DATABASE_URL (or DB_* variables) is present in the environment
    When the DB config is resolved
    Then the Sequelize connection uses the values from the environment
    And no database credentials are hardcoded in the config module

  @AC-5
  Scenario: The app boots, connects to the database, and loads all models with queryable associations
    Given a reachable PostgreSQL database
    When the DB layer authenticates the connection
    Then the connection succeeds without error
    And a smoke query that includes an association (for example Article with Tag and User) executes without error
