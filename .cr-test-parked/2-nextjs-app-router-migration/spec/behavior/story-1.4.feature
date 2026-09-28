Feature: Articles API — CRUD, Feed & Tags
  As an author and reader
  I want to create, read, update, delete, and browse articles with fast responses
  So that I can manage my content and discover others' without a slow feed

  # Story 1.4 — Covers REQ-F-12, REQ-F-14, REQ-F-17, REQ-NF-02, REQ-NF-04
  # Bound to the articles + tags services public surface.

  @AC-2
  Scenario: Creating an article returns it with a slug, author, and tag list
    Given a registered author "amy"
    When "amy" creates an article titled "Hello World" with tags "react, next"
    Then the article has slug "hello-world" and author "amy"
    And the article tag list contains "react" and "next"

  @AC-1
  Scenario: Listing articles returns them newest first with a count
    Given a registered author "ben"
    And "ben" has created an article titled "First Post"
    And "ben" has created an article titled "Second Post"
    When the global article list is requested
    Then the article count is 2
    And the first listed article is titled "Second Post"

  @AC-1
  Scenario: Listing can be filtered by tag
    Given a registered author "cara"
    And "cara" has created an article titled "Tagged" with tags "elixir"
    And "cara" has created an article titled "Untagged"
    When the article list is filtered by tag "elixir"
    Then the article count is 1
    And the first listed article is titled "Tagged"

  @AC-4
  Scenario: A feed page issues a bounded number of DB queries regardless of article count
    Given a registered author "dan"
    And "dan" has created 5 articles
    When the global article list is requested with query counting on
    Then the number of database queries is at most 6

  @AC-2
  Scenario: Reading a single article by slug returns it
    Given a registered author "eve"
    And "eve" has created an article titled "Readable"
    When the article "readable" is requested
    Then the article has slug "readable" and author "eve"

  @AC-2
  Scenario: Reading an unknown article is not found
    When the article "does-not-exist" is requested
    Then the article request is rejected as not found

  @AC-2
  Scenario: An author can update their own article
    Given a registered author "finn"
    And "finn" has created an article titled "Original"
    When "finn" updates the article "original" body to "new body"
    Then the article body is "new body"

  @AC-2
  Scenario: A non-author cannot update someone else's article
    Given a registered author "gwen"
    And a registered author "hank"
    And "gwen" has created an article titled "Guarded"
    When "hank" tries to update the article "guarded"
    Then the update is rejected as forbidden

  @AC-2
  Scenario: An author can delete their own article
    Given a registered author "ida"
    And "ida" has created an article titled "Temporary"
    When "ida" deletes the article "temporary"
    Then the article "temporary" no longer exists

  @AC-2
  Scenario: Creating an article requires a title
    Given a registered author "jack"
    When "jack" creates an article with no title
    Then the creation is rejected with a validation error

  @AC-5
  Scenario: The personal feed shows only followed authors' articles
    Given a registered author "kate"
    And a registered author "leo"
    And "kate" is following "leo"
    And "leo" has created an article titled "From Leo"
    And "kate" has created an article titled "From Kate"
    When "kate" requests the personal feed
    Then the feed count is 1
    And the first feed article is titled "From Leo"

  @AC-3
  Scenario: The tags endpoint lists all tag names
    Given a registered author "mia"
    And "mia" has created an article titled "Tagged Post" with tags "go, rust"
    When the tag list is requested
    Then the tag list contains "go" and "rust"
