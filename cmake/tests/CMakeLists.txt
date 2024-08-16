cmake_minimum_required(VERSION 3.29.0)
enable_testing()

project(cmake_tests LANGUAGES NONE)
add_subdirectory(test_assert)
add_subdirectory(test_code_test)