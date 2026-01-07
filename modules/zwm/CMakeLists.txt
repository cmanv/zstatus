cmake_minimum_required (VERSION 3.20)

# Project identification
project ("zwm")
set(PACKAGE_NAME "zstatus::zwm")
set(PACKAGE_VERSION "0.2")
set(CMAKE_C_COMPILER "/usr/bin/cc")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
message (STATUS "*** Building ${PACKAGE_NAME} ${PACKAGE_VERSION} ***")

# Tcl version
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")

# Substitute some variable names
set(PKG_INDEX pkgIndex.tcl)
configure_file(${zwm_SOURCE_DIR}/${PKG_INDEX} ${zwm_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${zwm_SOURCE_DIR}/zwm.tcl ${zwm_BINARY_DIR}/zwm.tcl @ONLY)

# Install files
set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/zwm)
install(FILES ${zwm_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${zwm_BINARY_DIR}/zwm.tcl DESTINATION ${PACKAGE_LIB})
