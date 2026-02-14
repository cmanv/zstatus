project(system)
set(LIBRARY_PROVIDE "zstatus::system::freebsd")

include_directories(/usr/local/include ${TCL_INCLUDE_PATH})
include_directories(${system_BINARY_DIR}/src)

set(TARGET_LIB freebsd${PACKAGE_VERSION})
add_library(${TARGET_LIB} SHARED)
target_sources(${TARGET_LIB} PRIVATE src/init.c src/freebsd.c)

set(PKG_INDEX pkgIndex.tcl)
configure_file(${system_SOURCE_DIR}/src/config.h.in ${system_BINARY_DIR}/src/config.h)
configure_file(${system_SOURCE_DIR}/${PKG_INDEX} ${system_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${system_SOURCE_DIR}/system.tcl ${system_BINARY_DIR}/system.tcl @ONLY)

set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/system)
install(TARGETS ${TARGET_LIB} DESTINATION ${PACKAGE_LIB})
install(FILES ${system_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${system_BINARY_DIR}/system.tcl DESTINATION ${PACKAGE_LIB})
