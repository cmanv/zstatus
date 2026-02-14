project(mail)
set(PKG_INDEX pkgIndex.tcl)
configure_file(${mail_SOURCE_DIR}/${PKG_INDEX} ${mail_BINARY_DIR}/${PKG_INDEX} @ONLY)
configure_file(${mail_SOURCE_DIR}/mail.tcl ${mail_BINARY_DIR}/mail.tcl @ONLY)

set(PACKAGE_LIB ${CMAKE_INSTALL_LIBDIR}/zstatus/mail)
install(FILES ${mail_BINARY_DIR}/${PKG_INDEX} DESTINATION ${PACKAGE_LIB})
install(FILES ${mail_BINARY_DIR}/mail.tcl DESTINATION ${PACKAGE_LIB})
