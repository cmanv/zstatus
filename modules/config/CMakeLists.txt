project(zstatus::config VERSION 1.0)
set(PKG_INDEX pkgIndex.tcl)
configure_file(${PROJECT_SOURCE_DIR}/${PKG_INDEX} ${PROJECT_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/config.tcl ${PROJECT_BINARY_DIR}/config.tcl @ONLY)

set(PROJECT_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/config)
install(FILES ${PROJECT_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PROJECT_LIB})
install(FILES ${PROJECT_BINARY_DIR}/config.tcl DESTINATION ${PROJECT_LIB})
