cmake_minimum_required (VERSION 3.20)

# Project identification
project ("workspace")
set(PACKAGE_NAME "zstatus::workspace")
set(PACKAGE_VERSION "0.2")
set(CMAKE_C_COMPILER "/usr/bin/cc")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
message (STATUS "*** Building ${PACKAGE_NAME} ${PACKAGE_VERSION} ***")

# Tcl version
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")

# Substitute some variable names
set(PKG_INDEX pkgIndex.tcl)
configure_file(${workspace_SOURCE_DIR}/${PKG_INDEX} ${workspace_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${workspace_SOURCE_DIR}/workspace.tcl ${workspace_BINARY_DIR}/workspace.tcl @ONLY)

# Install files
set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/workspace)
install(FILES ${workspace_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${workspace_BINARY_DIR}/workspace.tcl DESTINATION ${PACKAGE_LIB})
