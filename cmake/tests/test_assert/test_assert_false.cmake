include(assert)

cmake_policy(SET CMP0012 NEW)

# mock out message
function(message MODE MESSAGE)
    _message(DEBUG "[${MODE}] ${MESSAGE}")
    set(EXPECTED_MESSAGE "\nAssertion failed: TEST_VAR (value is 'OFF')\n")
    if(NOT MESSAGE STREQUAL EXPECTED_MESSAGE)
        _message(FATAL_ERROR "Assert issued incorrect message: ${MESSAGE}; expected ${EXPECTED_MESSAGE}")
    endif()
    if(NOT MODE STREQUAL "FATAL_ERROR")
        _message(FATAL_ERROR "Assert should have sent message at level FATAL_ERROR, actual was ${MODE}.")
    endif()
    
endfunction()

set(TEST_VAR "OFF")
assert(TEST_VAR)