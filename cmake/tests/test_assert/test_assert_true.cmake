include(assert)

# mock out message
function(message MODE MESSAGE)
    _message(DEBUG "[${MODE}] ${MESSAGE}")
    set(EXPECTED_MESSAGE  "assert(TEST_VAR) passed (TEST_VAR = TRUE)")
    if(NOT MESSAGE STREQUAL ${EXPECTED_MESSAGE})
    _message(FATAL_ERROR "Assert issued incorrect message: ${MESSAGE}; expected ${EXPECTED_MESSAGE}")
    endif()
    if(NOT MODE STREQUAL DEBUG)
        _message(FATAL_ERROR "Assert should have sent message at level DEBUG, actual was ${MODE}.")
    endif()
endfunction()

set(TEST_VAR TRUE)
assert(TEST_VAR)