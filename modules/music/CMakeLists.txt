cmake_minimum_required (VERSION 3.20)

# Project identification
project ("music")
set(PACKAGE_NAME "zstatus::music")
set(PACKAGE_VERSION "0.6")
set(LIBRARY_PROVIDE "zstatus::music::mpd")
set(CMAKE_C_COMPILER "/usr/bin/cc")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
message (STATUS "*** Building ${PACKAGE_NAME} ${PACKAGE_VERSION} ***")

# Tcl version
set(TCL_LIBRARY_VERSION "9.0")
set(TCL_INCLUDE_PATH "/usr/local/include/tcl9.0")

# Library build
add_definitions(-I ${music_BINARY_DIR}/src)
include_directories(/usr/local/include/mpd ${TCL_INCLUDE_PATH})
set(TARGET_LIB mpd${PACKAGE_VERSION})
add_library(${TARGET_LIB} SHARED)
target_sources(${TARGET_LIB} PRIVATE src/init.c src/mpd.c)
link_libraries(-L/usr/local/lib -lmpdclient)

# Substitute some variable names
set(PKG_INDEX pkgIndex.tcl)
configure_file(${music_SOURCE_DIR}/src/config.h.in ${music_BINARY_DIR}/src/config.h)
configure_file(${music_SOURCE_DIR}/${PKG_INDEX} ${music_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${music_SOURCE_DIR}/music.tcl ${music_BINARY_DIR}/music.tcl @ONLY)

# Install files
set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/music)
install(TARGETS ${TARGET_LIB} DESTINATION ${PACKAGE_LIB})
install(FILES ${music_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${music_BINARY_DIR}/music.tcl DESTINATION ${PACKAGE_LIB})
