cmake_minimum_required (VERSION 3.20)

# Project identification
project ("system")
set(PACKAGE_NAME "zstatus::system")
set(PACKAGE_VERSION "0.7")
set(LIBRARY_PROVIDE "zstatus::system::freebsd")
set(CMAKE_C_COMPILER "/usr/bin/cc")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
message (STATUS "*** Building ${PACKAGE_NAME} ${PACKAGE_VERSION} ***")

# Tcl version
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")

# Library build
set(TARGET_LIB freebsd${PACKAGE_VERSION})
add_definitions(-I ${system_BINARY_DIR}/src)
add_library(${TARGET_LIB} SHARED)
target_sources(${TARGET_LIB} PRIVATE src/init.c src/freebsd.c)
include_directories(/usr/local/include ${TCL_INCLUDE_PATH})

# Substitute some variable names
set(PKG_INDEX pkgIndex.tcl)
configure_file(${system_SOURCE_DIR}/src/config.h.in ${system_BINARY_DIR}/src/config.h)
configure_file(${system_SOURCE_DIR}/${PKG_INDEX} ${system_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${system_SOURCE_DIR}/system.tcl ${system_BINARY_DIR}/system.tcl @ONLY)

# Install files
set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/system)
install(TARGETS ${TARGET_LIB} DESTINATION ${PACKAGE_LIB})
install(FILES ${system_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${system_BINARY_DIR}/system.tcl DESTINATION ${PACKAGE_LIB})
