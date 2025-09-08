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
	set memused "M: [join [lindex $memstats 0]] "
	set swap [join [lindex $memstats 1]]
	if {[string length $swap]} {
		set memused "$memused\($swap\) "
	}
}

proc zstatus::system::set_arcsize {} {
	variable arcsize
	set arcstats [freebsd::getarcstats]
	set arcsize "ARC: [join [lindex $arcstats 0]] "
}

proc zstatus::system::set_netin {} {
	variable netin
	variable interface_in
	set inval [freebsd::getnetin $interface_in]
	set netin "$::arrowdown[join [lindex $inval 0]] "
}

proc zstatus::system::set_netout {} {
	variable netout
	variable interface_out
	set outval [freebsd::getnetout $interface_out]
	set netout "$::arrowup[join [lindex $outval 0]] "
}

proc zstatus::system::set_mixer {} {
	variable mixer
	set mixer "$::remix(mixer) [freebsd::getmixervol]"
}

proc zstatus::system::setup {bar item} {
	variable interface_in 
	variable interface_out
	switch $item {
		arcsize { }
		loadavg {
			bind $bar.loadavg <1> { exec xterm +sb -class top -e top & }
		}
		memused { }
		mixer {
			bind $bar.mixer <MouseWheel> {
				if {%D < 0} {
					exec mixer vol=-0.05
				} else {
					exec mixer vol=+0.05
				}
				zstatus::system::set_mixer
			}
		}
		netin {
			array set widget $::widgetarray(netin)
			set interface_in $widget(interface) 
		}
		netout {
			array set widget $::widgetarray(netout)
			set interface_out $widget(interface) 
		}
	}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
