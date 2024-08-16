cmake_minimum_required(VERSION 3.29)
project(test_code_tests
    DESCRIPTION "Tests for the code_test cmake Module"
)

set(SEARCH_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../..")
cmake_path(NORMAL_PATH SEARCH_PATH OUTPUT_VARIABLE MODULE_SEARCH_PATH)

enable_testing()

file(GLOB TEST_FILES ${CMAKE_CURRENT_SOURCE_DIR}/*.cmake)
foreach(TEST_FILE ${TEST_FILES}) 
    cmake_path(GET TEST_FILE STEM LAST_ONLY TEST_NAME)
    add_test(
        NAME ${TEST_NAME}
        COMMAND ${CMAKE_COMMAND} -D CMAKE_MODULE_PATH=${MODULE_SEARCH_PATH} -P ${TEST_FILE}

    )
endforeach()