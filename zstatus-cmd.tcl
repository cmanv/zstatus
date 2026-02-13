#!/usr/bin/env tclsh9.0
package require unix_sockets
package require zstatus::config

set action [split [lindex $::argv 0] :]
if {[llength $action] == 1} {
	set key [lindex $action 0]
	set value ""
} else {
	set key [lindex $action 0]
	set value [lindex $action 1]
}
set json "{\"$key\":\"$value\"}"

set socket "[zstatus::config::get cache_prefix default]/zstatus/socket"
if {[catch {set channel [unix_sockets::connect $socket]} error]} {
	puts stderr $error
	exit 1
}
puts $channel $json
close $channel
