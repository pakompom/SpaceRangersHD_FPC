cmake_minimum_required(VERSION 3.20)
project(rangers_native LANGUAGES C)
if(EMSCRIPTEN)
  add_compile_options(-pthread -fwasm-exceptions -sWASM_LEGACY_EXCEPTIONS=0)
  # SDL's browser backend needs explicit WebGL proxying for a blocking game loop on an application
  # pthread. Keep the small platform patch separate from the pinned upstream dependency.
  include(FetchContent)
  # A changed patch needs pristine sources, including in an existing build tree.
  file(SHA256 "${CMAKE_CURRENT_SOURCE_DIR}/sdl2-wasm.patch" SDL_PATCH_HASH)
  FetchContent_Declare(
    SDL2
    SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/sdl2-${SDL_PATCH_HASH}-src"
    URL https://codeload.github.com/libsdl-org/SDL/zip/refs/tags/release-2.32.10
    URL_HASH
      SHA512=001738b610b42a8f8badfd6af3402f0a1a8601034adef0b8c702dd2b1951dc1b71b733a6779d97499b6f7314d226ec0c8dcffeb753f35a5c51e995ca20bdd459
    PATCH_COMMAND patch -p1 -i "${CMAKE_CURRENT_SOURCE_DIR}/sdl2-wasm.patch")
  set(SDL_SHARED
      OFF
      CACHE BOOL "" FORCE)
  set(SDL_STATIC
      ON
      CACHE BOOL "" FORCE)
  set(SDL_ATOMIC
      ON
      CACHE BOOL "" FORCE)
  set(SDL_PTHREADS
      ON
      CACHE BOOL "" FORCE)
  set(SDL_TEST
      OFF
      CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(SDL2)
  set_target_properties(SDL2-static PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
endif()
set(OKGF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../vendor/okgf")
if(NOT EXISTS "${OKGF_ROOT}/CMakeLists.txt")
  message(FATAL_ERROR "Initialize dependencies with: git submodule update --init --recursive")
endif()
# Use host arithmetic for graphics on every target. FORCE also updates existing build directories
# that previously selected EXACT on x86.
set(OKGF_MATH_BACKEND
    NATIVE
    CACHE STRING "OKGF arithmetic backend" FORCE)
add_subdirectory("${OKGF_ROOT}" okgf)
set_target_properties(okgf PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
                                      ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
if(APPLE)
  set_target_properties(okgf PROPERTIES BUILD_WITH_INSTALL_NAME_DIR YES INSTALL_NAME_DIR "@rpath")
endif()
if(ANDROID)
  target_link_options(okgf PRIVATE "-Wl,-z,max-page-size=16384")
endif()
