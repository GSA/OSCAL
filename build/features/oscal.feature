Feature: Validate OSCAL Content
  As a developer
  I want to validate OSCAL content against appropriate metaschemas

  Background: 
    Given the following directories by type:
      | type    | paths |
      | catalog | ../src/specifications/profile-resolution/profile-resolution-examples/catalogs,../src/specifications/profile-resolution/profile-resolution-examples/output-expected,../src/specifications/profile-resolution/requirement-tests/catalogs |
      | profile | ../src/specifications/profile-resolution/profile-resolution-examples/full-test_profile.xml |
    And the OSCAL CLI tool is installed
    And the metaschema directory is "../src/metaschema"

  Scenario Outline: Validate OSCAL content
    When I validate "<type>" content in "<path>"
    Then all validations should pass without errors

    Examples:
      | type    | path |
      | catalog | ../src/specifications/profile-resolution/profile-resolution-examples/catalogs |
      | catalog | ../src/specifications/profile-resolution/profile-resolution-examples/output-expected |
      | catalog | ../src/specifications/profile-resolution/requirement-tests/catalogs |
      | profile | ../src/specifications/profile-resolution/profile-resolution-examples/full-test_profile.xml |
      | profile | ../src/specifications/valid-content/profile.xml|
      | catalog | ../src/specifications/valid-content/catalog.xml|
      | ssp | ../src/specifications/valid-content/ssp.xml|
      | poam | ../src/specifications/valid-content/poam.xml|
      | assessment-plan | ../src/specifications/valid-content/ap.xml|
      | assessment-results | ../src/specifications/valid-content/ar.xml|
