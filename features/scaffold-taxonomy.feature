Feature: Scaffold a custom taxonomy

  Scenario: Scaffold a taxonomy that uses Doctrine pluralization
    Given a WP install

    When I run `wp scaffold taxonomy fungus --raw`
    Then STDOUT should contain:
      """
      __( 'Popular fungi'
      """

  Scenario: Extended scaffolded taxonomy includes term_updated_messages
    Given a WP install

    When I run `wp scaffold taxonomy fungus`
    Then STDOUT should contain:
      """
      add_filter( 'term_updated_messages', 'fungus_updated_messages' );
      """
    And STDOUT should contain:
      """
      $messages['fungus'] = array(
      """
    And STDOUT should contain:
      """
      1 => __( 'Fungus added.', 'YOUR-TEXTDOMAIN' ),
      """
    And STDOUT should contain:
      """
      6 => __( 'Fungi deleted.', 'YOUR-TEXTDOMAIN' ),
      """
