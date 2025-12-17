Feature: User Authentication
  In order to securely access Eco Rangers features
  As a registered user or administrator
  I want to be able to login and, if new, register an account

  # US-01: Login User

  Scenario: User login successfully with valid credentials
    Given there is a user with email "rifat@gmail.com" and password "12345678"
    And I am on the login page
    When I fill in "email" with " rifat@gmail.com "
    And I fill in "password" with "12345678"
    And I press "Login"
    Then I should be logged in successfully
    And I should see "token"
    And I should have a valid auth token

  Scenario: User fails to login with invalid password
    Given there is a user with email "@rifatgmail.com " and password "12345678"
    And I am on the login page
    When I fill in "email" with "rifat@gmail.com "
    And I fill in "password" with "wrongpass"
    And I press "Login"
    Then I should see "Email atau password salah"
    And I should not be logged in

  # US-02: Registrasi User

  Scenario: New user registers successfully
    Given I am on the register page
    When I fill in "name" with "mbul"
    And I fill in "email" with "mbul@gmail.com"
    And I fill in "password" with "12345678"
    And I fill in "password_confirmation" with "12345678"
    And I press "Register"
    Then I should see "Registrasi berhasil"
    And an account with email "mbul@gmail.com" should exist
    And I should be able to login with email "mbul@gmail.com" and password "12345678"

  Scenario: New user registration fails when email is already taken
    Given there is a user with email "rifat@gmail.com" and password "12345678"
    And I am on the register page
    When I fill in "name" with "Rifat"
    And I fill in "email" with "rifat@gmail.com"
    And I fill in "password" with "12345678"
    And I fill in "password_confirmation" with "12345678"
    And I press "Register"
    Then I should see "The email has already been taken."
    And a new account with email "rifat@gmail.com" should not be created
