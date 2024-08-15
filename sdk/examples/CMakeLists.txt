project(sdk_examples
    DESCRIPTION "Examples of how to use the SDK"
)

include(code_tests)

install_components(
    COMPONENTS sdk
)

set(EXAMPLES example_one example_two)
foreach(EXAMPLE ${EXAMPLES})
    add_example(
        NAME ${EXAMPLE}
        COMPONENT ${PROJECT_NAME}
        SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${EXAMPLE}
        REQUIRED_COMPONENTS sdk
    )
endforeach()
