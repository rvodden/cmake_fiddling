cmake_minimum_required(VERSION 3.29)
project(test_code_tests
    DESCRIPTION "Tests for the code_test cmake Module"
)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ../../)

enable_testing()
add_subdirectory(test_install_components)
