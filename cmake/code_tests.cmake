#[[
    # Code Tests
    
    This module is designed to make it trival to add tests which configure and 
    compile code against a library. There are three parts:

    - component installation
    - code tests
    - examples

    Component installation is used to install components created using the `cmake`
    `install` infrastructure into sandbox directories against which further tests
    can be run.

    Code tests are tests which consist of a `cmake` project; i.e. a directory
    with a `CMakeLists.txt` file and likely some source code. The code test
    infrastructure contained in this module will create ctest tests which configure, 
    compile and run these projects.

    Examples are Code tests which are also added to a `cmake` `install` component
    and can therefore be run from the appropriate location within the sandbox
    installation.


#]]

#[[
    Using the function `install_component` looks like this:
    ```
        install_components(
            DIRECTORY ${CMAKE_BINARY_DIR}/place/to/install/component
            COMPONENTS component1 component2
        )
    ```
    
    Calling this function will register a pair of fixtures with `ctest`:

        - component1_installed
        - component2_installed
    
    Tests which include these fixtures in their `FIXTURES_REQUIRED` property
    will be guaranteed that the component `component1` will be installed in
    `${CMAKE_BINARY_DIR}/place/to/install/component/component1` and that
    `component2` will be installed in 
    `${CMAKE_BINARY_DIR}/place/to/install/component/component2` respectively.

    The variables `component1_INSTALL_DIR` and `component2_INSTALL_DIR` will
    be set to the respective installation directories.

#]]
function(install_components)
    set(options "")
    set(oneValueArgs DIRECTORY)
    set(multiValueArgs COMPONENTS)
    cmake_parse_arguments(PARSE_ARGV 0 INSTALL_COMPONENTS "${options}" "${oneValueArgs}" "${multiValueArgs}")
    message(VERBOSE "Registering a fixture to install components: ${INSTALL_COMPONENTS_COMPONENTS}")

    if(NOT DEFINED INSTALL_COMPONENTS_DIRECTORY)
        set(INSTALL_COMPONENTS_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/components")
        message(DEBUG "DIRECTORY not specified. Falling back on default of ${INSTALL_COMPONENTS_DIRECTORY}")
    endif()

    foreach(COMPONENT ${INSTALL_COMPONENTS_COMPONENTS})
        # Define a fixture to install the HDAS library
        string(TOUPPER ${COMPONENT} COMPONENT_UPPER)
        set(${COMPONENT_UPPER}_INSTALL_DIR "${INSTALL_COMPONENTS_DIRECTORY}/${COMPONENT}")
        set(${COMPONENT_UPPER}_INSTALL_DIR "${INSTALL_COMPONENTS_DIRECTORY}/${COMPONENT}" PARENT_SCOPE)
        if(NOT TEST install_${COMPONENT})
            message(DEBUG "Registering a fixture to install ${COMPONENT} to ${${COMPONENT_UPPER}_INSTALL_DIR}")
            add_test(
                NAME install_${COMPONENT}
                COMMAND ${CMAKE_COMMAND}
                --install .
                --prefix ${${COMPONENT_UPPER}_INSTALL_DIR}
                --component ${COMPONENT}
                WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
                COMMAND_EXPAND_LISTS
            )
            set_tests_properties(install_${COMPONENT} PROPERTIES FIXTURES_SETUP ${COMPONENT}_installed)
        endif()

        if(NOT TEST remove_${COMPONENT})
            # Define a fixture to uninstall the HDAS library
            message(DEBUG "Registering a fixture to delete the ${${COMPONENT_UPPER}_INSTALL_DIR} directory")
            add_test(
                NAME remove_${COMPONENT}
                COMMAND ${CMAKE_COMMAND}
                    -E remove_directory ${${COMPONENT_UPPER}_INSTALL_DIR}
            )
            set_tests_properties(remove_${COMPONENT} PROPERTIES FIXTURES_CLEANUP ${COMPONENT}_installed)
            
            set_property(
                TEST 
                    install_${COMPONENT}
                    remove_${COMPONENT}
                APPEND PROPERTY
                    LABELS host
            )
        else()
            message(DEBUG "remove_$[COMPONENT} installation fixtures already configured.")
        endif()
    endforeach()
endfunction()

#[[
    Using the function `add_code_test` looks like this:
    ```
        add_code_test(
            NAME code_test_name
            [SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/code_test_name]
            [BUILD_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/code_test_name]
            [TEST_PREFIX code_test]
            [REQUIRED_COMPONENTS component1 component2]
        )
    ```

    If SOURCE_DIRECTORY is ommitted it will default to ${CMAKE_CURRNET_SOURCE_DIR}/code_test_name
    If BUILD_DIRECTORY is omitted it will default to ${CMAKE_CURRENT_BINARY_DIR}/code_test_name
    If TEST_PREFIX is omitted it will default to "code_test"

    This function creates a pair of fixtures: `create_code_test_name_build_directory` and `remove_code_test_name_build_directory` which
    respectively create and remove the build directory specified when the function was called, or the default if ommitted.

    It then creates a pair of fixtures for each `REQUIRED_COMPONENT` one to install the component and one to remove it.

    Finally the two (soon to be three) tests are created which configure and compile (soon to run) the project in the directory.
#]]
function(add_code_test)
    set(options "")
    set(oneValueArgs NAME SOURCE_DIRECTORY BUILD_DIRECTORY)
    set(multiValueArgs REQUIRED_COMPONENTS)
    cmake_parse_arguments(PARSE_ARGV 0 ADD_CODE_TEST "${options}" "${oneValueArgs}" "${multiValueArgs}")
    message(VERBOSE "Add code test: ${ADD_CODE_TEST_NAME}")

    if(NOT DEFINED ADD_CODE_TEST_SOURCE_DIRECTORY)
        set(ADD_CODE_TEST_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ADD_CODE_TEST_NAME})
    endif()

    if(NOT DEFINED ADD_CODE_TEST_BUILD_DIRECTORY)
        set(ADD_CODE_TEST_BUILD_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${ADD_CODE_TEST_NAME})
    endif()
    
    if(NOT DEFINED ADD_CODE_TEST_TEST_PREFIX)
        set(ADD_CODE_TEST_TEST_PREFIX code_test)
    endif()

    # Define a fixture to create the build directory for the code test
    add_test(
        NAME create_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory
        COMMAND ${CMAKE_COMMAND} -E make_directory ${ADD_CODE_TEST_BUILD_DIRECTORY}
    )
    set_tests_properties(
        create_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory
        PROPERTIES
            FIXTURES_SETUP ${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory)
    
    # Define a fixture to remove the build directory for the code test
    add_test(
        NAME remove_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${ADD_CODE_TEST_BUILD_DIRECTORY}
    )
    set_tests_properties(
        remove_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory
        PROPERTIES
            FIXTURES_CLEANUP ${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory
    )
    
    foreach(COMPONENT ${ADD_CODE_TEST_REQUIRED_COMPONENTS})
        message(VERBOSE "Associating ${COMPONENT} with ${ADD_CODE_TEST_NAME}")
        string(TOUPPER ${COMPONENT} COMPONENT_UPPER)
        if(NOT DEFINED ${COMPONENT_UPPER}_INSTALL_DIR)
            message(FATAL_ERROR "Do not know where ${COMPONENT} is installed, required by ${ADD_CODE_TEST_NAME}.")
        endif()
        list(APPEND COMPONENT_ARGUMENT_LIST "-D${COMPONENT_UPPER}_DIR=${${COMPONENT_UPPER}_INSTALL_DIR}/lib/cmake/${COMPONENT_UPPER}")
        list(APPEND FIXTURES_REQUIRED "${COMPONENT}_installed")
    endforeach()
    string(JOIN ";" FIXTURES_REQUIRED_STRING ${FIXTURES_REQUIRED})

    if(DEFINED CMAKE_TOOLCHAIN_FILE)
        list(APPEND ARGUMENT_LIST "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
    endif()

    # Create a test which runs `cmake` in configure mode
    add_test(
        NAME test_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_configures
        COMMAND ${CMAKE_COMMAND}
            -G "${CMAKE_GENERATOR}"
            ${ARGUMENT_LIST}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/cmake
            ${COMPONENT_ARGUMENT_LIST} 
            ${ADD_CODE_TEST_SOURCE_DIRECTORY}
        WORKING_DIRECTORY ${ADD_CODE_TEST_BUILD_DIRECTORY}
        COMMAND_EXPAND_LISTS
    )
    # Configuration requires HDAS to be installed and requires the build directory
    set_tests_properties(
        test_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_configures 
        PROPERTIES 
            FIXTURES_REQUIRED "${FIXTURES_REQUIRED_STRING};${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory")
    # Declare this test as a fixture so that compilation can be declared after it
    set_tests_properties(
        test_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_configures
        PROPERTIES
            FIXTURES_SETUP ${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_configured)

    # Create a test which runs `cmake` in build mode 
    add_test(
        NAME test_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_compiles
        COMMAND ${CMAKE_COMMAND}
            --build
            .
        WORKING_DIRECTORY ${ADD_CODE_TEST_BUILD_DIRECTORY}
    )
    # Compilation requires HDAS to be installed, requires the build directory, and requires configuration to have happened.
    set_tests_properties(
        test_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_compiles 
        PROPERTIES 
            FIXTURES_REQUIRED "${FIXTURES_REQUIRED_STRING};${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory;${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_configured"
    )

    # Give both configuration and compilation tests the `host` label so they are run on the build machine not the test target
    set_property(
        TEST
            create_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory 
            remove_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_directory
            test_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_configures
            test_${ADD_CODE_TEST_TEST_PREFIX}_${ADD_CODE_TEST_NAME}_compiles
        APPEND PROPERTY
            LABELS host
    )
endfunction()

#[[
    Using the function `add_example` looks like this:
    ```
        add_example(
            NAME example_name
            [COMPONENT ${PROJECT_NAME}]
            [SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/example_name]
            [DESTINATION ${PROJECT_NAME}]
            [REQUIRED_COMPONENTS component1 component2]
        )
    ```
    If COMPONENT is ommitted it will default to ${PROJECT_NAME}
    If SOURCE_DIRECTORY is ommitted it will default to ${CMAKE_CURRNET_SOURCE_DIR}/example_name
    If DESTINATION is ommitted it will default to ${PROJECT_NAME}
    if BUILD_DIRECTORY is omitted it will default to ${CMAKE_CURRENT_BINARY_DIR}/examples/example_name/build

    This function is a specialisation of `add_code_test` and is intended to be used for examples
    which will be packaged up and shipped to clients. 
    
    Firstly this function installs the `SOURCE_DIRECTORY` to `/${DESTINATION}` within the `COMPONENT`, the expectation
    behing that subsequently `cpack` will be used to pack this component up for customers.

    Then this function creates, if not already created, fixtures which install and remove `COMPONENT` to the default 
    locations defined in the `install_components` funciton above.
    and the source directory set to the location to which `COMPONENT` will be installed. The 
    
    
#]]
function(add_example)
    set(options "")
    set(oneValueArgs NAME COMPONENT SOURCE_DIRECTORY DESTINATION)
    set(multiValueArgs REQUIRED_COMPONENTS)
    cmake_parse_arguments(PARSE_ARGV 0 ADD_EXAMPLE "${options}" "${oneValueArgs}" "${multiValueArgs}")
    message(VERBOSE "Adding example: ${ADD_EXAMPLE_NAME}")

    if(NOT DEFINED ADD_EXAMPLE_NAME)
        message(FATAL_ERROR "NAME is a required parameter of `add_example`")
    endif()

    if(NOT DEFINED ADD_EXAMPLE_COMPONENT)
        set(ADD_EXAMPLE_COMPONENT ${PROJECT_NAME})
    endif()
    
    if(NOT DEFINED ADD_EXAMPLE_SOURCE_DIRECTORY)
        set(ADD_EXAMPLE_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ADD_EXAMPLE_NAME})
    endif()
    
    if(NOT DEFINED ADD_EXAMPLE_DESTINATION)
        set(ADD_EXAMPLE_DESTINATION ${PROJECT_NAME})
    endif()

    # install the SOURCE_DIRECTORY to the DESTINATION within COMPONENT
    install(DIRECTORY ${ADD_EXAMPLE_SOURCE_DIRECTORY} DESTINATION "examples" COMPONENT ${ADD_EXAMPLE_COMPONENT})

    # create the fixtures to install the compmonent if necessary
    if(NOT TARGET install_${COMPONENT})
        install_components(
            COMPONENTS ${ADD_EXAMPLE_COMPONENT}
        )
    endif()

    # create the code test
    string(TOUPPER ${ADD_EXAMPLE_COMPONENT} COMPONENT_UPPER)
    message(DEBUG "NAME: ${ADD_EXAMPLE_NAME}")
    message(DEBUG "SOURCE_DIRECTORY: ${${COMPONENT_UPPER}_INSTALL_DIR}/${ADD_EXAMPLE_NAME}")
    message(DEBUG "BULD_DIRECTORY: ${${COMPONENT_UPPER}_INSTALL_DIR}/${ADD_EXAMPLE_NAME}/build")
    add_code_test(
        NAME ${ADD_EXAMPLE_NAME}
        SOURCE_DIRECTORY ${${COMPONENT_UPPER}_INSTALL_DIR}/examples/${ADD_EXAMPLE_NAME}
        BUILD_DIRECTORY ${${COMPONENT_UPPER}_INSTALL_DIR}/examples/${ADD_EXAMPLE_NAME}/build
        TEST_PREFIX example
        REQUIRED_COMPONENTS ${ADD_EXAMPLE_COMPONENT} ${ADD_EXAMPLE_REQUIRED_COMPONENTS}
    )

endfunction()