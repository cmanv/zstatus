cmake_minimum_required (VERSION 3.20)

# Project identification
project ("zstatus")
set(PACKAGE_NAME "zstatus")
set(PACKAGE_VERSION "alpha1")
message (STATUS "*** Building ${PACKAGE_NAME} ${PACKAGE_VERSION} ***")

# Tcl version
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")
include(GNUInstallDirs)

# Add modules
add_subdirectory(modules/config)
add_subdirectory(modules/desktop)
add_subdirectory(modules/devices)
add_subdirectory(modules/mail)
add_subdirectory(modules/metar)
add_subdirectory(modules/music)
add_subdirectory(modules/remixicon)
add_subdirectory(modules/system)

# Substitute some variable names
set(LIBDIR ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
set(LIBEXECDIR ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBEXECDIR})
configure_file(${zstatus_SOURCE_DIR}/zstatus.tk ${zstatus_BINARY_DIR}/zstatus.tk @ONLY)
configure_file(${zstatus_SOURCE_DIR}/zstatus-send ${zstatus_BINARY_DIR}/zstatus-send @ONLY)
configure_file(${zstatus_SOURCE_DIR}/zstatus ${zstatus_BINARY_DIR}/zstatus @ONLY)

# Install files
install(PROGRAMS ${zstatus_SOURCE_DIR}/zstatus-send.tcl DESTINATION ${CMAKE_INSTALL_LIBEXECDIR})
install(PROGRAMS ${zstatus_BINARY_DIR}/zstatus.tk DESTINATION ${CMAKE_INSTALL_LIBEXECDIR})
install(PROGRAMS ${zstatus_BINARY_DIR}/zstatus-send DESTINATION ${CMAKE_INSTALL_BINDIR})
install(PROGRAMS ${zstatus_BINARY_DIR}/zstatus DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES man/zstatus.1 DESTINATION ${CMAKE_INSTALL_MANDIR}/man1)
