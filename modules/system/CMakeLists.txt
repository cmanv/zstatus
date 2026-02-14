project(zstatus::system VERSION 1.0)
set(LIBRARY_PROVIDE "zstatus::system::freebsd")

include_directories(/usr/local/include ${TCL_INCLUDE_PATH})
include_directories(${PROJECT_BINARY_DIR}/src)

set(TARGET_LIB freebsd${PROJECT_VERSION})
add_library(${TARGET_LIB} SHARED)
target_sources(${TARGET_LIB} PRIVATE src/init.c src/freebsd.c)

set(PKG_INDEX pkgIndex.tcl)
configure_file(${PROJECT_SOURCE_DIR}/src/config.h.in ${PROJECT_BINARY_DIR}/src/config.h)
configure_file(${PROJECT_SOURCE_DIR}/${PKG_INDEX} ${PROJECT_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/system.tcl ${PROJECT_BINARY_DIR}/system.tcl @ONLY)

set(PROJECT_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/system)
install(TARGETS ${TARGET_LIB} DESTINATION ${PROJECT_LIB})
install(FILES ${PROJECT_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PROJECT_LIB})
install(FILES ${PROJECT_BINARY_DIR}/system.tcl DESTINATION ${PROJECT_LIB})
