project(library)

file(GLOB SOURCES ${PROJECT_SOURCE_DIR}/*.cxx)
add_library(${PROJECT_NAME} SHARED ${SOURCES})
target_link_libraries(${PROJECT_NAME} PUBLIC sdk)