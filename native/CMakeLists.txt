cmake_minimum_required(VERSION 3.20)
project(rangers_native LANGUAGES C)
set(OKGF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../vendor/okgf")
if(NOT EXISTS "${OKGF_ROOT}/CMakeLists.txt")
  message(FATAL_ERROR "Initialize dependencies with: git submodule update --init --recursive")
endif()
# Use host arithmetic, retaining exact x87 on x86 targets.
set(OKGF_TARGET_CPU "${CMAKE_SYSTEM_PROCESSOR}")
if(CMAKE_OSX_ARCHITECTURES)
  set(OKGF_TARGET_CPU "${CMAKE_OSX_ARCHITECTURES}")
endif()
string(TOLOWER "${OKGF_TARGET_CPU}" OKGF_TARGET_CPU)
if(OKGF_TARGET_CPU MATCHES "^(x86_64|amd64|i[3-6]86|x86)$")
  set(OKGF_MATH_BACKEND
      EXACT
      CACHE STRING "OKGF arithmetic backend" FORCE)
else()
  set(OKGF_MATH_BACKEND
      NATIVE
      CACHE STRING "OKGF arithmetic backend" FORCE)
endif()
add_subdirectory("${OKGF_ROOT}" okgf)
set_target_properties(okgf PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
if(APPLE)
  set_target_properties(okgf PROPERTIES BUILD_WITH_INSTALL_NAME_DIR YES INSTALL_NAME_DIR "@rpath")
endif()
if(ANDROID)
  target_link_options(okgf PRIVATE "-Wl,-z,max-page-size=16384")
endif()
