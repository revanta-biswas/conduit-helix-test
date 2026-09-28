Feature: Auth API — Register, Login & httpOnly Cookie Session
  As an end user
  I want to register and log in, with my session persisted via a secure cookie
  So that I stay authenticated across page loads without my token being exposed to XSS

  # Story 1.2 — Covers REQ-F-10, REQ-F-15, REQ-F-16, REQ-F-18, REQ-NF-01, REQ-NF-03
  # Scenarios bind to the public service surface (src/lib/services/users.js) and the
  # auth library (src/lib/auth.js), not to Route Handler HTTP internals.

  @AC-1
  Scenario: Registering a valid user issues a session and returns the user without the password
    Given no user exists with email "alice@conduit.io"
    When I register with username "alice", email "alice@conduit.io", and password "sup3rsecret"
    Then the registration succeeds
    And the returned user has email "alice@conduit.io" and username "alice"
    And the returned user does not expose a password field
    And a signed session token is produced for the user

  @AC-1
  Scenario Outline: Registration rejects invalid input with a validation error (tightened rules)
    Given no user exists with email "<email>"
    When I register with username "<username>", email "<email>", and password "<password>"
    Then the registration is rejected with a validation error

    Examples:
      | username | email             | password  |
      | al       | ok@conduit.io     | sup3rsecret |
      | alice    | not-an-email      | sup3rsecret |
      | alice    | ok2@conduit.io    | short     |

  @AC-1
  Scenario: Registration rejects a duplicate email
    Given a user already exists with email "bob@conduit.io"
    When I register with username "bobby", email "bob@conduit.io", and password "sup3rsecret"
    Then the registration is rejected because the email is already taken

  @AC-1
  Scenario: Registration rejects a duplicate username (tightened rule)
    Given a user already exists with username "carol"
    When I register with username "carol", email "carol2@conduit.io", and password "sup3rsecret"
    Then the registration is rejected because the username is already taken

  @AC-5
  Scenario: Logging in with correct credentials returns the user and a session token
    Given a registered user with email "dave@conduit.io" and password "sup3rsecret"
    When I log in with email "dave@conduit.io" and password "sup3rsecret"
    Then the login succeeds
    And a signed session token is produced for the user

  @AC-5
  Scenario: Logging in with a wrong password is rejected
    Given a registered user with email "erin@conduit.io" and password "sup3rsecret"
    When I log in with email "erin@conduit.io" and password "wrongpass"
    Then the login is rejected with a validation error

  @AC-5
  Scenario: Logging in with an unknown email is rejected as not found
    Given no user exists with email "ghost@conduit.io"
    When I log in with email "ghost@conduit.io" and password "whatever1"
    Then the login is rejected because the user is not found

  @AC-2
  Scenario: A valid session token resolves to the current user
    Given a registered user with email "frank@conduit.io" and password "sup3rsecret"
    And a session token signed for that user
    When the session token is verified
    Then it resolves to the user with email "frank@conduit.io"

  @AC-2
  Scenario: A request with no session resolves to no user (soft auth)
    Given no session token is present
    When the session is resolved for a public request
    Then no user is resolved and no error is thrown

  @AC-4
  Scenario: The startup path never auto-alters the database schema
    Given the DB layer module
    When its source is inspected
    Then it contains no schema-altering sync call
