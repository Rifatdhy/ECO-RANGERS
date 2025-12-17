Feature: User Logout
  In order to keep my account secure on shared devices
  As a logged-in user or administrator
  I want to be able to logout from the application

  Scenario: User logs out successfully
    Given I am logged in as "rifat@gmail.com"
    And I am on the "Dashboard User" page
    When I press "Logout"
    Then I should be redirected to the login page
    And my auth token should be invalidated
    And I should not be able to access "Dashboard User" without logging in again

  Scenario: Admin logs out successfully
    Given I am logged in as admin "admin@gmail.com"
    And I am on the "Dashboard Admin" page
    When I press "Logout"
    Then I should be redirected to the login page
    And my auth token should be invalidated
    And I should not be able to access "Dashboard Admin" without logging in again
