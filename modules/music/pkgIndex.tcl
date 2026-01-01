package ifneeded @LIBRARY_PROVIDE@ @PACKAGE_VERSION@ [list load [file join $dir lib@TARGET_LIB@.so]]
package ifneeded @PACKAGE_NAME@ @PACKAGE_VERSION@ [list source [file join $dir music.tcl]]
