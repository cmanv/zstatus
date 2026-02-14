project(devices)
set(PKG_INDEX pkgIndex.tcl)
configure_file(${devices_SOURCE_DIR}/${PKG_INDEX} ${devices_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${devices_SOURCE_DIR}/devices.tcl ${devices_BINARY_DIR}/devices.tcl @ONLY)

set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/devices)
install(FILES ${devices_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${devices_BINARY_DIR}/devices.tcl DESTINATION ${PACKAGE_LIB})
