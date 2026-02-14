project(remixicon)
set(PKG_INDEX pkgIndex.tcl)
configure_file(${remixicon_SOURCE_DIR}/${PKG_INDEX} ${remixicon_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${remixicon_SOURCE_DIR}/remixicon.tcl ${remixicon_BINARY_DIR}/remixicon.tcl @ONLY)

set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/remixicon)
install(FILES ${remixicon_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${remixicon_BINARY_DIR}/remixicon.tcl DESTINATION ${PACKAGE_LIB})
