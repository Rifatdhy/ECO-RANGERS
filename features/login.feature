Feature: Login

  Scenario Outline: User login
    Given I am on the login page
    When I enter my <email> and <password>
    And I tap the login button
    Then I should see the <outcome>

    Examples:
      | email             | password | outcome                |
      | admin@gmail.com   | 12345678 | home page              |
      | admin@gmail.com   | wrong    | error message          |
