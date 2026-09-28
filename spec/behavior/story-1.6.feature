Feature: Auth Pages & Session — Login, Register, Settings
  As an end user
  I want to register, log in, and manage my account settings through pages that use my cookie-based session
  So that I have the same account-management experience as today, without localStorage-based auth

  # Story 1.6 — Covers REQ-F-24, REQ-F-25, REQ-F-28
  # Bound to the observable non-UI logic: server session helper, client-api error mapping,
  # and the page payload builders. UI rendering itself is ve/Playwright territory (Story 1.9+).

  @AC-3
  Scenario: A valid session cookie resolves to the current user server-side
    Given a registered user "amy" with a session cookie
    When the server session is resolved from that cookie
    Then the resolved session user is "amy"

  @AC-3
  Scenario: No session cookie resolves to no user (no localStorage involved)
    Given no session cookie
    When the server session is resolved from that cookie
    Then no session user is resolved

  @AC-1
  Scenario: The login page builds the Conduit login payload
    When a login form is submitted with email "amy@conduit.io" and password "sup3rsecret"
    Then the login payload is the Conduit shape with that email and password

  @AC-1
  Scenario: The register page builds the Conduit register payload
    When a register form is submitted with username "amy", email "amy@conduit.io" and password "sup3rsecret"
    Then the register payload is the Conduit shape with that username, email and password

  @AC-2
  Scenario: The settings page builds a partial update payload omitting a blank password
    When a settings form is submitted with bio "hi", image "http://x/y.png" and a blank password
    Then the settings payload contains bio and image but not password

  @AC-1
  Scenario: A server validation error envelope is normalised into displayable messages
    Given an API error response with body messages "Email already exists" and "Username taken"
    When the client normalises the error
    Then the displayable errors are "Email already exists" and "Username taken"

  @AC-5
  Scenario: Logout clears the session cookie
    When the logout action runs
    Then a cleared session cookie is produced
