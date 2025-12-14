Feature: Login

  Scenario Outline: User login
    Given I am on the login page
    When I enter my <username> and <password>
    And I tap the login button
    Then I should see the <outcome>

    Examples:
      | username | password | outcome                |
      | user1    | pass1    | home page              |
      | user2    | wrong    | error message          |
