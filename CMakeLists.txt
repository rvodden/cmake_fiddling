cmake_minimum_required(VERSION 3.29)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

enable_testing()

project(sdk_testing_example)

add_subdirectory(sdk)
add_subdirectory(library)