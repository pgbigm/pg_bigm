cmake_minimum_required(VERSION 3.29.0)

set(PROJECT_NAME "pg_bigm")
set(PROJECT_ID "pg_bigm")
set(VENDOR "NTT DATA Corporation")

project("${PROJECT_ID}")

set(POSTGRESQL_DIR "${CMAKE_INSTALL_PREFIX}"
  CACHE PATH "PostgreSQL binary directory")
set(POSTGRESQL_VERSION "unknown"
  CACHE STRING "PostgreSQL version")

set(LIBRARY_NAME "lib${PROJECT_ID}")

set(EXTENSION_DIR "lib")
set(EXTENSION_DATA_DIR "share/extension")
set(DOCUMENT_DIR "share/${PROJECT_ID}")

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_ID}.control" CONTROL)
string(REGEX REPLACE ".*default_version = '([0-9.]+)'.*" "\\1" VERSION "${CONTROL}")
string(REGEX REPLACE "([0-9]+)\\.([0-9]+)" "\\1" VERSION_MAJOR "${VERSION}")
string(REGEX REPLACE "([0-9]+)\\.([0-9]+)" "\\2" VERSION_MINOR "${VERSION}")

include_directories(
  "${POSTGRESQL_DIR}/include/server/port/win32_msvc"
  "${POSTGRESQL_DIR}/include/server/port/win32"
  "${POSTGRESQL_DIR}/include/server"
  "${POSTGRESQL_DIR}/include"
)

link_directories(
  "${POSTGRESQL_DIR}/lib"
)

set(SOURCES
  "bigm_op.c"
  "bigm_gin.c")
set_source_files_properties(${SOURCES}
  PROPERTIES
  COMPILE_FLAGS "/EHsc")
add_library("${LIBRARY_NAME}" SHARED ${SOURCES})
set_target_properties("${LIBRARY_NAME}"
  PROPERTIES
  OUTPUT_NAME "${PROJECT_ID}")
target_link_libraries("${LIBRARY_NAME}"
  "postgres.lib")
install(TARGETS "${LIBRARY_NAME}"
  DESTINATION "${EXTENSION_DIR}")

install(FILES
  "${PROJECT_SOURCE_DIR}/${PROJECT_ID}.control"
  DESTINATION "${EXTENSION_DATA_DIR}")

install(FILES
  "${PROJECT_SOURCE_DIR}/${PROJECT_ID}--${VERSION}.sql"
  DESTINATION "${EXTENSION_DATA_DIR}")

install(FILES
  "${PROJECT_SOURCE_DIR}/${PROJECT_ID}--1.0--1.1.sql"
  DESTINATION "${EXTENSION_DATA_DIR}")


install(FILES
  "${PROJECT_SOURCE_DIR}/LICENSE"
  DESTINATION "${DOCUMENT_DIR}")


set(CPACK_GENERATOR "ZIP")
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)
set(CPACK_PACKAGE_VERSION_MAJOR "${VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${VERSION_MINOR}")
set(CPACK_PACKAGE_VENDOR "${VENDOR}")
if(CMAKE_CL_64)
  set(PACKAGE_SYSTEM_NAME "x64")
else()
  set(PACKAGE_SYSTEM_NAME "x86")
endif()
set(CPACK_PACKAGE_FILE_NAME
  "${PROJECT_ID}-${VERSION}-postgresql-${POSTGRESQL_VERSION}-${PACKAGE_SYSTEM_NAME}")

include(CPack)
