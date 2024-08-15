cmake_minimum_required(VERSION 3.29)
project(test_code_test_install_components
    DESCRIPTION "Tests for the code_test cmake Module"
)

enable_testing()

set(TEST_NAME test_installed_component_adds_install_and_remove_tests)
set(SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME})
set(WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME})

add_test(
    NAME ${TEST_NAME}_create_working_directory
    COMMAND ${CMAKE_COMMAND} -E make_directory ${WORKING_DIRECTORY}
)
set_tests_properties(${TEST_NAME}_create_working_directory PROPERTIES FIXTURES_SETUP ${TEST_NAME}_working_directory)
add_test(
    NAME ${TEST_NAME}_remove_working_directory
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${WORKING_DIRECTORY}
)
set_tests_properties(${TEST_NAME}_remove_working_directory PROPERTIES FIXTURES_CLEANUP ${TEST_NAME}_working_directory)
add_test(
    NAME ${TEST_NAME}
    WORKING_DIRECTORY ${WORKING_DIRECTORY}
    COMMAND ${CMAKE_COMMAND} 
        -DCMAKE_MODULE_PATH=${CMAKE_CURRENT_SOURCE_DIR}/../../.. ${SOURCE_DIRECTORY}
        --log-level=debug
)
set_tests_properties(${TEST_NAME} PROPERTIES 
    FIXTURES_REQUIRED ${TEST_NAME}_working_directory
)