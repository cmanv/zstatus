#!/usr/bin/env tclsh9.0
package require zstatus::system::freebsd

namespace eval zstatus::system {
	namespace export set_loadavg set_memused set_arcsize set_netin set_netout\
		 set_mixer
}

proc zstatus::system::set_loadavg {} {
	variable loadavg
	set loadavg "C: [freebsd::getloadavg] "
}

proc zstatus::system::set_memused {} {
	variable memused
	set memstats [freebsd::getmemstats]
	set memused "M: [lindex $memstats 0] "
	set swap [lindex $memstats 1]
	if {[string length $swap]} {
		set memused "$memused\($swap\) "
	}
}

proc zstatus::system::set_arcsize {} {
	variable arcsize
	set arcsize "ARC: [lindex [freebsd::getarcstats] 0] "
}

proc zstatus::system::set_netin {} {
	variable netin
	variable if_in
	set netin "$::unicode(arrowdown)[lindex [freebsd::getnetin $if_in] 0] "
}

proc zstatus::system::set_netout {} {
	variable netout
	variable if_out
	set netout "$::unicode(arrowup)[lindex [freebsd::getnetout $if_out] 0] "
}

proc zstatus::system::set_mixer {} {
	variable mixer
	variable mixer_icon
	set mixer "$mixer_icon [freebsd::getmixervol]"
}

proc zstatus::system::setup {bar item} {
	switch $item {
	arcsize { }
	loadavg {
		bind $bar.loadavg <1> { exec xterm +sb -class top -e top & }
	}
	memused { }
	mixer {
		variable mixer_icon
		set mixer_icon $::unicode(mixer)
		set_mixer
		bind $bar.mixer <MouseWheel> {
			if {%D < 0} {
				exec mixer vol=-0.05
			} else {
				exec mixer vol=+0.05
			}
			zstatus::system::set_mixer
		}
		dict set ::messagedict mixer_volume {action system::set_mixer arg 0}
	}
	netin {
		variable if_in
		set if_in [dict get $::widgetdict netin interface]
	}
	netout {
		variable if_out
		set if_out [dict get $::widgetdict netout interface]
	}}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
