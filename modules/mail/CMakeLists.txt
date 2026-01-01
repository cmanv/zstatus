cmake_minimum_required (VERSION 3.20)

# Project identification
project ("mail")
set(PACKAGE_NAME "zstatus::mail")
set(PACKAGE_VERSION "0.4")

# Tcl version
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")

# Substitute some variable names
set(PKG_INDEX pkgIndex.tcl)
configure_file(${mail_SOURCE_DIR}/${PKG_INDEX} ${mail_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${mail_SOURCE_DIR}/mail.tcl ${mail_BINARY_DIR}/mail.tcl @ONLY)

# Install files
set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/mail)
install(FILES ${mail_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${mail_BINARY_DIR}/mail.tcl DESTINATION ${PACKAGE_LIB})
