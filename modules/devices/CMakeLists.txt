cmake_minimum_required (VERSION 3.20)

# Project identification
project ("devices")
set(PACKAGE_NAME "zstatus::devices")
set(PACKAGE_VERSION "0.4")

# Tcl version
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")

# Substitute some variable names
set(PKG_INDEX pkgIndex.tcl)
configure_file(${devices_SOURCE_DIR}/${PKG_INDEX} ${devices_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${devices_SOURCE_DIR}/devices.tcl ${devices_BINARY_DIR}/devices.tcl @ONLY)

# Install files
set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/devices)
install(FILES ${devices_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${devices_BINARY_DIR}/devices.tcl DESTINATION ${PACKAGE_LIB})
