cmake_minimum_required (VERSION 3.20)

# Project identification
project ("metar")
set(PACKAGE_NAME "zstatus::metar")
set(PACKAGE_VERSION "1.0")
message (STATUS "*** Building ${PACKAGE_NAME} ${PACKAGE_VERSION} ***")

# Tcl version
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")

# Substitute some variable names
set(PKG_INDEX pkgIndex.tcl)
configure_file(${metar_SOURCE_DIR}/${PKG_INDEX} ${metar_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${metar_SOURCE_DIR}/metar.tcl ${metar_BINARY_DIR}/metar.tcl @ONLY)
configure_file(${metar_SOURCE_DIR}/metar_thread.tcl ${metar_BINARY_DIR}/metar_thread.tcl @ONLY)

# Install files
set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/metar)
install(FILES ${metar_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${metar_BINARY_DIR}/metar.tcl DESTINATION ${PACKAGE_LIB})
install(FILES ${metar_BINARY_DIR}/metar_thread.tcl DESTINATION ${PACKAGE_LIB})
