add_library(leanmain STATIC TheoremAI.cpp)
set_target_properties(leanmain PROPERTIES
  ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/temp
  OUTPUT_NAME leanmain)

# library must contain at least one non-manifest file
# We use `CONFIGURE` instead of `WRITE` so as to avoid touching the file on each run
file(CONFIGURE OUTPUT ${CMAKE_BINARY_DIR}/temp/empty.c CONTENT "")
add_library(leanmanifest STATIC ${CMAKE_BINARY_DIR}/temp/empty.c manifest.rc)
set_target_properties(leanmanifest PROPERTIES
  ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/theorem_ai
  OUTPUT_NAME leanmanifest)

if(LLVM)
  if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(LLVM_SYSTEM_LIBS "-lz -ltinfo")
  elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Darwin")
    # macOS doesn't have -Bstatic, so let cmake search for the libraries
    find_library(LIBZ NAMES z REQUIRED)
    find_library(NCURSES NAMES ncurses REQUIRED)
    set(LLVM_SYSTEM_LIBS "${LIBZ} ${NCURSES}")
  else()
    set(LLVM_SYSTEM_LIBS "-lz")
  endif()
  if(NOT ("${CMAKE_SYSTEM_NAME}" MATCHES "Darwin"))
    string(APPEND LEAN_EXE_LINKER_FLAGS " `llvm-config --link-static --ldflags --libs nativecodegen` -Wl,-Bstatic ${LLVM_SYSTEM_LIBS} -Wl,-Bdynamic")
  else()
    string(APPEND LEAN_EXE_LINKER_FLAGS " `llvm-config --ldflags --libs nativecodegen` ${LLVM_SYSTEM_LIBS}")
  endif()
  if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    string(APPEND LEAN_EXE_LINKER_FLAGS " -lole32 -luuid")
  endif()
endif()

add_custom_target(theorem_ai ALL
  WORKING_DIRECTORY ${LEAN_SOURCE_DIR}
  DEPENDS leanshared leanmain
  COMMAND $(MAKE) -f ${CMAKE_BINARY_DIR}/stdlib.make theorem_ai
  COMMAND_EXPAND_LISTS)

# use executable of current stage for tests
string(REGEX REPLACE "^([a-zA-Z]):" "/\\1" LEAN_BIN "${CMAKE_BINARY_DIR}/bin")

add_test(lean_help1    "${CMAKE_BINARY_DIR}/bin/theorem_ai" --help)
add_test(lean_help2    "${CMAKE_BINARY_DIR}/bin/theorem_ai" -h)
add_test(lean_version1 "${CMAKE_BINARY_DIR}/bin/theorem_ai" --version)
if (NOT ${EMSCRIPTEN})
add_test(lean_version2 "${CMAKE_BINARY_DIR}/bin/theorem_ai" --v)
endif()
add_test(lean_ghash1   "${CMAKE_BINARY_DIR}/bin/theorem_ai" -g)
add_test(lean_ghash2   "${CMAKE_BINARY_DIR}/bin/theorem_ai" --githash)
add_test(lean_unknown_option bash "${LEAN_SOURCE_DIR}/cmake/check_failure.sh" "${CMAKE_BINARY_DIR}/bin/theorem_ai" "-z")
add_test(lean_unknown_file1 bash "${LEAN_SOURCE_DIR}/cmake/check_failure.sh" "${CMAKE_BINARY_DIR}/bin/theorem_ai" "boofoo.theorem_ai")

if(${EMSCRIPTEN})
  configure_file("${LEAN_SOURCE_DIR}/bin/TheoremAI.in" "${CMAKE_BINARY_DIR}/bin/theorem_ai")
endif()

# LEANC_OPTS in CXX is necessary for macOS c++ to find its headers
set(TEST_VARS "PATH=${LEAN_BIN}:$PATH ${LEAN_TEST_VARS} CXX='${CMAKE_CXX_COMPILER} ${LEANC_OPTS}' LEANC_OPTS='${LEANC_OPTS}'")

# theorem_ai TESTS
file(GLOB LEANTESTS "${LEAN_SOURCE_DIR}/../tests/theorem_ai/*.theorem_ai")
FOREACH(T ${LEANTESTS})
  if(NOT T MATCHES "\\.#")
    GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
    add_test(NAME "leantest_${T_NAME}"
             WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/theorem_ai"
             COMMAND bash -c "${TEST_VARS} ./test_single.sh ${T_NAME}")
  endif()
ENDFOREACH(T)

# theorem_ai RUN TESTS
file(GLOB LEANRUNTESTS "${LEAN_SOURCE_DIR}/../tests/theorem_ai/run/*.theorem_ai")
FOREACH(T ${LEANRUNTESTS})
  if(NOT T MATCHES "\\.#")
    GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
    add_test(NAME "leanruntest_${T_NAME}"
             WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/theorem_ai/run"
             COMMAND bash -c "${TEST_VARS} ./test_single.sh ${T_NAME}")
  endif()
ENDFOREACH(T)

# theorem_ai RUN doc/examples
file(GLOB LEANDOCEXS "${LEAN_SOURCE_DIR}/../doc/examples/*.theorem_ai")
FOREACH(T ${LEANDOCEXS})
  if(NOT T MATCHES "\\.#")
    GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
    add_test(NAME "leandocex_${T_NAME}"
             WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../doc/examples"
             COMMAND bash -c "${TEST_VARS} ./test_single.sh ${T_NAME}")
  endif()
ENDFOREACH(T)

# theorem_ai COMPILER TESTS
file(GLOB LEANCOMPTESTS "${LEAN_SOURCE_DIR}/../tests/compiler/*.theorem_ai")
FOREACH(T ${LEANCOMPTESTS})
  GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
  add_test(NAME "leancomptest_${T_NAME}"
           WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/compiler"
           COMMAND bash -c "${TEST_VARS} ./test_single.sh ${T_NAME}")
ENDFOREACH(T)

add_test(NAME leancomptest_foreign
         WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/compiler/foreign"
         COMMAND bash -c "${LEAN_BIN}/leanmake --always-make")
add_test(NAME leancomptest_doc_example
         WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../doc/examples/compiler"
         COMMAND bash -c "export ${TEST_VARS}; leanmake --always-make bin && ./build/bin/test hello world")

# theorem_ai INTERPRETER TESTS
file(GLOB LEANINTERPTESTS "${LEAN_SOURCE_DIR}/../tests/compiler/*.theorem_ai")
FOREACH(T ${LEANINTERPTESTS})
  if(NOT EXISTS "${T}.no_interpreter")
    GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
    add_test(NAME "leaninterptest_${T_NAME}"
             WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/compiler"
             COMMAND bash -c "${TEST_VARS} ./test_single_interpret.sh ${T_NAME}")
  endif()
ENDFOREACH(T)

# theorem_ai BENCHMARK TESTS
# do not test all .theorem_ai files in bench/
file(GLOB LEANBENCHTESTS "${LEAN_SOURCE_DIR}/../tests/bench/*.TheoremAI.expected.out")
FOREACH(T_OUT ${LEANBENCHTESTS})
  string(REPLACE ".expected.out" "" T ${T_OUT})
  GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
  add_test(NAME "leanbenchtest_${T_NAME}"
            WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/bench"
            COMMAND bash -c "${TEST_VARS} ./test_single.sh ${T_NAME}")
ENDFOREACH(T_OUT)

file(GLOB LEANINTERPTESTS "${LEAN_SOURCE_DIR}/../tests/plugin/*.theorem_ai")
FOREACH(T ${LEANINTERPTESTS})
  GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
  add_test(NAME "leanplugintest_${T_NAME}"
           WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/plugin"
           COMMAND bash -c "${TEST_VARS} ./test_single.sh ${T_NAME}")
ENDFOREACH(T)

# theorem_ai TESTS using --trust=0
file(GLOB LEANT0TESTS "${LEAN_SOURCE_DIR}/../tests/theorem_ai/trust0/*.theorem_ai")
FOREACH(T ${LEANT0TESTS})
  GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
  add_test(NAME "leant0test_${T_NAME}"
           WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/theorem_ai/trust0"
           COMMAND bash -c "${TEST_VARS} ./test_single.sh ${T_NAME}")
ENDFOREACH(T)

# theorem_ai PACKAGE TESTS
file(GLOB LEANPKGTESTS "${LEAN_SOURCE_DIR}/../tests/pkg/*")
FOREACH(T ${LEANPKGTESTS})
  if(EXISTS ${T}/test.sh)
    GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
    add_test(NAME "leanpkgtest_${T_NAME}"
            WORKING_DIRECTORY "${T}"
            COMMAND bash -c "${TEST_VARS} ./test.sh")
  endif()
ENDFOREACH(T)

# theorem_ai SERVER TESTS
file(GLOB LEANTESTS "${LEAN_SOURCE_DIR}/../tests/theorem_ai/server/*.theorem_ai")
FOREACH(T ${LEANTESTS})
  if(NOT T MATCHES "\\.#")
    GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
    add_test(NAME "leanservertest_${T_NAME}"
             WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/theorem_ai/server"
             COMMAND bash -c "${TEST_VARS} ./test_single.sh ${T_NAME}")
  endif()
ENDFOREACH(T)

# theorem_ai INTERACTIVE SERVER TESTS
file(GLOB LEANTESTS "${LEAN_SOURCE_DIR}/../tests/theorem_ai/interactive/*.theorem_ai")
FOREACH(T ${LEANTESTS})
  if(NOT T MATCHES "\\.#" AND NOT T MATCHES "run.theorem_ai")
    GET_FILENAME_COMPONENT(T_NAME ${T} NAME)
    add_test(NAME "leaninteractivetest_${T_NAME}"
             WORKING_DIRECTORY "${LEAN_SOURCE_DIR}/../tests/theorem_ai/interactive"
             COMMAND bash -c "${TEST_VARS} ./test_single.sh ${T_NAME}")
  endif()
ENDFOREACH(T)

# Create a lake test for each test and examples subdirectory of `lake`
# which contains a `test.sh` file, excluding the following test(s):
# bootstrap: too slow
# toolchain: requires elan to download toolchain
# online: downloads remote repositories
file(GLOB_RECURSE LEANLAKETESTS
  #"${LEAN_SOURCE_DIR}/lake/tests/test.sh"
  "${LEAN_SOURCE_DIR}/lake/examples/test.sh")
FOREACH(T ${LEANLAKETESTS})
  if(NOT T MATCHES ".*(lake-packages|bootstrap|toolchain|online).*")
    GET_FILENAME_COMPONENT(T_DIR ${T} DIRECTORY)
    GET_FILENAME_COMPONENT(DIR_NAME ${T_DIR} NAME)
    add_test(NAME "leanlaketest_${DIR_NAME}"
             WORKING_DIRECTORY "${T_DIR}"
             COMMAND bash -c "
               set -eu
               export ${TEST_VARS}
               LAKE=lake ./test.sh")
  endif()
ENDFOREACH(T)
