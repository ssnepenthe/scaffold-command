Feature: Import users from CSV

  Scenario: Importing users from a CSV file
    Given a WP install
    And a users.csv file:
      """
      user_login,user_email,display_name,role
      bobjones,bobjones@example.com,Bob Jones,contributor
      newuser1,newuser1@example.com,New User,author
      admin,admin@example.com,Existing User,administrator
      """

    When I try `wp user import-csv users-incorrect.csv --skip-update`
    Then STDERR should be:
      """
      Error: Missing file: users-incorrect.csv
      """

    When I run `wp user import-csv users.csv`
    Then STDOUT should not be empty

    When I run `wp user list --format=count`
    Then STDOUT should be:
      """
      3
      """

    When I run `wp user list --format=json`
    Then STDOUT should be JSON containing:
      """
      [{
        "user_login":"admin",
        "display_name":"Existing User",
        "user_email":"admin@example.com",
        "roles":"administrator"
      }]
      """

  Scenario: Import new users on multisite
    Given a WP multisite install
    And a user-invalid.csv file:
      """
      user_login,user_email,display_name,role
      bob-jones,bobjones@example.com,Bob Jones,contributor
      """
    And a user-valid.csv file:
      """
      user_login,user_email,display_name,role
      bobjones,bobjones@example.com,Bob Jones,contributor
      """

    When I try `wp user import-csv user-invalid.csv`
    Then STDERR should contain:
      """
      lowercase letters (a-z) and numbers
      """

    When I run `wp user import-csv user-valid.csv`
    Then STDOUT should not be empty

    When I run `wp user get bobjones --field=display_name`
    Then STDOUT should be:
      """
      Bob Jones
      """

  Scenario: Import new users but don't update existing
    Given a WP install
    And a users.csv file:
      """
      user_login,user_email,display_name,role
      bobjones,bobjones@example.com,Bob Jones,contributor
      newuser1,newuser1@example.com,New User,author
      admin,admin@example.com,Existing User,administrator
      """

    When I run `wp user create bobjones bobjones@example.com --display_name="Robert Jones" --role=administrator`
    Then STDOUT should not be empty

    When I run `wp user import-csv users.csv --skip-update`
    Then STDOUT should not be empty

    When I run `wp user list --format=count`
    Then STDOUT should be:
      """
      3
      """

    When I run `wp user get bobjones --fields=user_login,display_name,user_email,roles --format=json`
    Then STDOUT should be JSON containing:
      """
      {
        "user_login":"bobjones",
        "display_name":"Robert Jones",
        "user_email":"bobjones@example.com",
        "roles":"administrator"
      }
      """

  Scenario: Import users from a CSV file generated by `wp user list`
    Given a WP install

    When I run `wp user delete 1 --yes`
    And I run `wp user create bobjones bobjones@example.com --display_name="Bob Jones" --role=contributor`
    And I run `wp user create billjones billjones@example.com --display_name="Bill Jones" --role=administrator`
    And I run `wp user add-role billjones author`
    Then STDOUT should not be empty

    When I run `wp user list --field=user_login | wc -l`
    Then STDOUT should be:
      """
      2
      """

    When I run `wp user list --format=csv > users.csv`
    Then the users.csv file should exist

    When I run `wp user delete $(wp user list --format=ids) --yes`
    Then STDOUT should not be empty

    When I run `wp user list --field=user_login | wc -l`
    Then STDOUT should be:
      """
      0
      """

    When I run `wp user import-csv users.csv`
    Then STDOUT should not be empty

    When I run `wp user list --fields=display_name,roles`
    Then STDOUT should be a table containing rows:
      | display_name      | roles                |
      | Bob Jones         | contributor          |
      | Bill Jones        | administrator,author |
