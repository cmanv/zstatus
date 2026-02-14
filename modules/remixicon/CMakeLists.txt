project(zstatus::remixicon VERSION 1.0)
set(PKG_INDEX pkgIndex.tcl)
configure_file(${PROJECT_SOURCE_DIR}/${PKG_INDEX} ${PROJECT_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/remixicon.tcl ${PROJECT_BINARY_DIR}/remixicon.tcl @ONLY)

set(PROJECT_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/remixicon)
install(FILES ${PROJECT_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PROJECT_LIB})
install(FILES ${PROJECT_BINARY_DIR}/remixicon.tcl DESTINATION ${PROJECT_LIB})
