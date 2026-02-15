project(zstatus::music VERSION ${PROJECT_VERSION})
set(LIBRARY_PROVIDE "zstatus::music::mpd")

include_directories(-I /usr/local/include)
include_directories(${TCL_INCLUDE_PATH})
include_directories(${PROJECT_BINARY_DIR}/src)

set(TARGET_LIB mpd${PROJECT_VERSION})
add_library(${TARGET_LIB} SHARED)
target_sources(${TARGET_LIB} PRIVATE src/init.c src/mpd.c)
link_libraries(-lmpdclient)

configure_file(${PROJECT_SOURCE_DIR}/src/config.h.in ${PROJECT_BINARY_DIR}/src/config.h)
configure_file(${PROJECT_SOURCE_DIR}/${PKG_INDEX} ${PROJECT_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/music.tcl ${PROJECT_BINARY_DIR}/music.tcl @ONLY)

set(PROJECT_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/music)
install(TARGETS ${TARGET_LIB} DESTINATION ${PROJECT_LIB})
install(FILES ${PROJECT_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PROJECT_LIB})
install(FILES ${PROJECT_BINARY_DIR}/music.tcl DESTINATION ${PROJECT_LIB})
