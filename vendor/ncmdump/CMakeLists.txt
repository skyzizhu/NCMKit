cmake_minimum_required(VERSION 3.14)

project(ncmdump LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(NCMDUMP_BUILD_CLI "Build the ncmdump command line executable." ON)
option(NCMDUMP_BUILD_LIBRARY "Build the reusable libncmdump target." ON)
set(NCMDUMP_LIBRARY_TYPE "STATIC" CACHE STRING "Library type for libncmdump (STATIC or SHARED).")
set_property(CACHE NCMDUMP_LIBRARY_TYPE PROPERTY STRINGS STATIC SHARED)

find_package(ZLIB)
find_package(TagLib REQUIRED)

if(MSVC)
  add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/execution-charset:utf-8>")
endif()

file(GLOB COMMON_HEADERS src/include/*.h)
file(GLOB COMMON_SOURCES src/ncmcrypt.cpp src/utils/*.cpp)
file(GLOB EXECUTABLE_SOURCES src/main.cpp)
file(GLOB LIBRARY_HEADERS src/lib/libncmdump.h)
file(GLOB LIBRARY_SOURCES src/lib/*.cpp)
file(GLOB WIN_SOURCES src/platform/win32_init.cpp)

set(NCMDUMP_PLATFORM_SOURCES)
if(WIN32)
  list(APPEND NCMDUMP_PLATFORM_SOURCES ${WIN_SOURCES})
endif()

if(NCMDUMP_BUILD_LIBRARY)
  add_library(ncmdump_lib ${NCMDUMP_LIBRARY_TYPE}
    ${COMMON_HEADERS}
    ${COMMON_SOURCES}
    ${LIBRARY_HEADERS}
    ${LIBRARY_SOURCES}
    ${NCMDUMP_PLATFORM_SOURCES}
  )

  target_include_directories(ncmdump_lib
    PUBLIC
      ${CMAKE_CURRENT_SOURCE_DIR}/src/include
      ${CMAKE_CURRENT_SOURCE_DIR}/src/lib
  )
  if(WIN32)
    set_target_properties(ncmdump_lib PROPERTIES OUTPUT_NAME "libncmdump")
  else()
    set_target_properties(ncmdump_lib PROPERTIES OUTPUT_NAME "ncmdump")
  endif()
  target_link_libraries(ncmdump_lib PUBLIC TagLib::tag)
endif()

if(NCMDUMP_BUILD_CLI)
  add_executable(ncmdump_exec
    ${COMMON_HEADERS}
    ${COMMON_SOURCES}
    ${EXECUTABLE_SOURCES}
    ${NCMDUMP_PLATFORM_SOURCES}
  )

  set_target_properties(ncmdump_exec PROPERTIES OUTPUT_NAME "ncmdump")
  target_include_directories(ncmdump_exec PRIVATE src/include)
  target_link_libraries(ncmdump_exec PRIVATE TagLib::tag)
endif()

if(WIN32 AND MSVC)
  # 强制所有配置（Debug/Release 等）使用静态 C 运行时库
  foreach(flag_var
    CMAKE_CXX_FLAGS
    CMAKE_C_FLAGS
    CMAKE_CXX_FLAGS_DEBUG
    CMAKE_CXX_FLAGS_RELEASE
  )
    if(${flag_var})
      string(REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
    endif()
  endforeach()
endif()

include(GNUInstallDirs)

if(NCMDUMP_BUILD_LIBRARY)
  install(TARGETS ncmdump_lib
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  install(FILES ${LIBRARY_HEADERS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/libncmdump)
  install(FILES ${COMMON_HEADERS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/ncmdump)
endif()

if(NCMDUMP_BUILD_CLI)
  install(TARGETS ncmdump_exec
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  )
endif()
