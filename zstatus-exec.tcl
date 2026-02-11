#!/usr/bin/env tclsh9.0
package require unix_sockets
package require zstatus::config
set socket "[zstatus::config::get cache_prefix default]/zstatus/socket"
set action [lindex $::argv 0]
if {[catch {set channel [unix_sockets::connect $socket]} error]} {
	puts stderr $error
	exit 1
}
puts $channel $action 
close $channel
