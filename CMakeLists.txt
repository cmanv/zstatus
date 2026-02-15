cmake_minimum_required (VERSION 3.20)

project(zstatus VERSION 0.4)
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")
set(CMAKE_C_COMPILER "/usr/bin/cc")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(PKG_INDEX pkgIndex.tcl)
include(GNUInstallDirs)
add_subdirectory(modules/config)
add_subdirectory(modules/devices)
add_subdirectory(modules/mail)
add_subdirectory(modules/metar)
add_subdirectory(modules/music)
add_subdirectory(modules/remixicon)
add_subdirectory(modules/system)
add_subdirectory(modules/zwm)

set(LIBDIR ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
set(LIBEXECDIR ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBEXECDIR})

configure_file(${PROJECT_SOURCE_DIR}/zstatus.tk ${PROJECT_BINARY_DIR}/zstatus.tk @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/zstatus-cmd ${PROJECT_BINARY_DIR}/zstatus-cmd @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/zstatus ${PROJECT_BINARY_DIR}/zstatus @ONLY)

install(PROGRAMS ${PROJECT_SOURCE_DIR}/zstatus-cmd.tcl DESTINATION ${CMAKE_INSTALL_LIBEXECDIR})
install(PROGRAMS ${PROJECT_BINARY_DIR}/zstatus.tk DESTINATION ${CMAKE_INSTALL_LIBEXECDIR})
install(PROGRAMS ${PROJECT_BINARY_DIR}/zstatus-cmd DESTINATION ${CMAKE_INSTALL_BINDIR})
install(PROGRAMS ${PROJECT_BINARY_DIR}/zstatus DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES man/zstatus.1 DESTINATION ${CMAKE_INSTALL_MANDIR}/man1)

message (STATUS "<<< ${PROJECT_NAME} version ${PROJECT_VERSION} is configured. >>>")
