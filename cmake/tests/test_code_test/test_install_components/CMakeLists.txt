cmake_minimum_required(VERSION 3.29)

project(test_installed_component_adds_install_and_remove_tests)

include(code_tests)
include(assert)

# given a component called `component` which contains a directory called `place`
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} DESTINATION "place" COMPONENT component)

# when I call `install_components` with the components argument set to `component`
install_components(
    COMPONENTS component
)

# then tests are created called `install_component` and `remove_component`
set(EXPECTED_TESTS install_component remove_component)
foreach(EXPECTED_TEST ${EXPECTED_TESTS})
    assert_is_test(${EXPECTED_TEST})
endforeach()

# and the install component is registered to setup a fixture called `component_installed`
assert_is_fixture_setup(install_component component_installed)
assert_is_fixture_cleanup(remove_component component_installed)

