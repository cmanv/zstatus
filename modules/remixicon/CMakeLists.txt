cmake_minimum_required (VERSION 3.20)

# Project identification
project ("remixicon")
set(PACKAGE_NAME "zstatus::remixicon")
set(PACKAGE_VERSION "4.6.0")

# Tcl version
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")

# Substitute some variable names
set(PKG_INDEX pkgIndex.tcl)
configure_file(${remixicon_SOURCE_DIR}/${PKG_INDEX} ${remixicon_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${remixicon_SOURCE_DIR}/remixicon.tcl ${remixicon_BINARY_DIR}/remixicon.tcl @ONLY)

# Install files
set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/remixicon)
install(FILES ${remixicon_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${remixicon_BINARY_DIR}/remixicon.tcl DESTINATION ${PACKAGE_LIB})
