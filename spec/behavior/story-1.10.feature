Feature: Article List Read Path Under the Amended REQ-F-17
  As an author and reader
  I want article lists and feeds to stay fast without the read mechanism being fixed to one Sequelize pattern
  So that the list read path can use whichever bounded-query design fits, while responses stay identical

  # Story 1.10 — Covers REQ-F-17@v2, REQ-NF-02
  # Created by CR-1 (spec/plans/change-requests/CR-1/). Supersedes Story 1.4 AC-4.
  # Bound to the articles service list/feed surface.

  @AC-1
  Scenario: The global list returns articles through the chosen bounded-query read path
    Given a registered author "nina"
    And "nina" has created an article titled "Read Path" with tags "sql, perf"
    When the global article list is requested
    Then the article count is 1
    And the first listed article is titled "Read Path"
    And the first listed article has tags "sql, perf"

  @AC-1
  Scenario: The personal feed returns followed authors' articles through the same read path
    Given a registered author "omar"
    And a registered author "pia"
    And "pia" follows "omar"
    And "omar" has created an article titled "Followed Post"
    When the personal feed is requested by "pia"
    Then the article count is 1
    And the first listed article is titled "Followed Post"

  @AC-2
  Scenario: Query count does not grow with the number of articles returned
    Given a registered author "quinn"
    And "quinn" has created 1 article
    When the global article list is requested with query counting on
    Then the recorded query count is retained as the baseline
    Given "quinn" has created 49 further articles
    When the global article list is requested with query counting on
    Then the number of database queries does not exceed the baseline by more than the fixed per-request overhead

  @AC-3
  Scenario: Every listed article is fully populated
    Given a registered author "rhea"
    And a registered author "sam"
    And "sam" follows "rhea"
    And "rhea" has created an article titled "Complete Row" with tags "one, two"
    And "sam" has favorited the article "complete-row"
    When the global article list is requested by "sam"
    Then the first listed article has tags "one, two"
    And the first listed article has author "rhea" with following true
    And the first listed article has favorited true and favoritesCount 1

  @AC-3
  Scenario: An anonymous request gets fully populated rows with viewer flags defaulted
    Given a registered author "tom"
    And "tom" has created an article titled "Anon View" with tags "three"
    When the global article list is requested anonymously
    Then the first listed article has tags "three"
    And the first listed article has author "tom" with following false
    And the first listed article has favorited false and favoritesCount 0

  @AC-4
  Scenario: No list or feed code path issues a database call per article
    When the list and feed code paths are inspected
    Then no list or feed code path contains a loop issuing a database call per iteration

  @AC-5
  Scenario: A newly created article appears in the next list response
    Given a registered author "uma"
    When "uma" creates an article titled "Fresh" with tags "new"
    And the global article list is requested
    Then the first listed article is titled "Fresh"
    And the first listed article has tags "new"

  @AC-5
  Scenario: An updated article's changes appear in the next list response
    Given a registered author "vik"
    And "vik" has created an article titled "Before Edit" with tags "old"
    When "vik" updates the article "before-edit" to title "After Edit" with tags "new"
    And the global article list is requested
    Then the first listed article is titled "After Edit"
    And the first listed article has tags "new"

  @AC-5
  Scenario: A favorite toggle is reflected in the next list response
    Given a registered author "wes"
    And a registered author "xena"
    And "wes" has created an article titled "Favoritable"
    When "xena" favorites the article "favoritable"
    And the global article list is requested by "xena"
    Then the first listed article has favorited true and favoritesCount 1
    When "xena" unfavorites the article "favoritable"
    And the global article list is requested by "xena"
    Then the first listed article has favorited false and favoritesCount 0

  @AC-5
  Scenario: A deleted article is absent from the next list response
    Given a registered author "yuri"
    And "yuri" has created an article titled "Doomed"
    When "yuri" deletes the article "doomed"
    And the global article list is requested
    Then the article count is 0
