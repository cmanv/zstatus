project(config)
set(PKG_INDEX pkgIndex.tcl)
configure_file(${config_SOURCE_DIR}/${PKG_INDEX} ${config_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${config_SOURCE_DIR}/config.tcl ${config_BINARY_DIR}/config.tcl @ONLY)

set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/config)
install(FILES ${config_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${config_BINARY_DIR}/config.tcl DESTINATION ${PACKAGE_LIB})
