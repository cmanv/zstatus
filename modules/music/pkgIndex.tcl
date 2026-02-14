package ifneeded @LIBRARY_PROVIDE@ @PROJECT_VERSION@ [list load [file join $dir lib@TARGET_LIB@.so]]
package ifneeded @PROJECT_NAME@ @PROJECT_VERSION@ [list source [file join $dir music.tcl]]
