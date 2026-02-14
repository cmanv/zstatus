project(music)
set(LIBRARY_PROVIDE "zstatus::music::mpd")

include_directories(/usr/local/include/mpd ${TCL_INCLUDE_PATH})
include_directories(${music_BINARY_DIR}/src)

set(TARGET_LIB mpd${PACKAGE_VERSION})
add_library(${TARGET_LIB} SHARED)
target_sources(${TARGET_LIB} PRIVATE src/init.c src/mpd.c)
link_libraries(-L/usr/local/lib -lmpdclient)

set(PKG_INDEX pkgIndex.tcl)
configure_file(${music_SOURCE_DIR}/src/config.h.in ${music_BINARY_DIR}/src/config.h)
configure_file(${music_SOURCE_DIR}/${PKG_INDEX} ${music_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${music_SOURCE_DIR}/music.tcl ${music_BINARY_DIR}/music.tcl @ONLY)

set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/music)
install(TARGETS ${TARGET_LIB} DESTINATION ${PACKAGE_LIB})
install(FILES ${music_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${music_BINARY_DIR}/music.tcl DESTINATION ${PACKAGE_LIB})
