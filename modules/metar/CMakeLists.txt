project(zstatus::metar VERSION ${PROJECT_VERSION})
configure_file(${PROJECT_SOURCE_DIR}/${PKG_INDEX} ${PROJECT_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/metar.tcl ${PROJECT_BINARY_DIR}/metar.tcl @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/metar_thread.tcl ${PROJECT_BINARY_DIR}/metar_thread.tcl @ONLY)

set(PROJECT_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/metar)
install(FILES ${PROJECT_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PROJECT_LIB})
install(FILES ${PROJECT_BINARY_DIR}/metar.tcl DESTINATION ${PROJECT_LIB})
install(FILES ${PROJECT_BINARY_DIR}/metar_thread.tcl DESTINATION ${PROJECT_LIB})
