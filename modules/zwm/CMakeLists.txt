project(zwm)
set(PKG_INDEX pkgIndex.tcl)
configure_file(${zwm_SOURCE_DIR}/${PKG_INDEX} ${zwm_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${zwm_SOURCE_DIR}/zwm.tcl ${zwm_BINARY_DIR}/zwm.tcl @ONLY)

set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/zwm)
install(FILES ${zwm_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${zwm_BINARY_DIR}/zwm.tcl DESTINATION ${PACKAGE_LIB})
