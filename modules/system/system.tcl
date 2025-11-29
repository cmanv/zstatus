#!/usr/bin/env tclsh9.0
package require zstatus::system::freebsd

namespace eval zstatus::system {
	namespace export set_loadavg set_memused set_arcsize set_netin set_netout\
		 set_mixer

	variable memstats_visible 0
	variable neottat_visible 0
}

proc zstatus::system::set_theme {theme} {
	variable systheme
	variable bartheme
	set bartheme [dict get $::widgetdict statusbar $theme]
	set systheme [dict get $::widgetdict netstat $theme]
}

proc zstatus::system::set_loadavg {} {
	variable loadavg
	set loadavg "C: [freebsd::getloadavg] "
}

proc zstatus::system::set_memused {} {
	variable memused
	set memused "M: [lindex [freebsd::getpercmemused] 0] "
	update_memstats
}

proc zstatus::system::set_arcsize {} {
	variable arcsize
	set arcsize "ARC: [lindex [freebsd::getarcstats] 0] "
}

proc zstatus::system::set_netin {} {
	variable netin
	variable if_in
	set netin "$::unicode(arrow-down)[lindex [freebsd::getnetin $if_in] 0] "
}

proc zstatus::system::set_netout {} {
	variable netout
	variable if_out
	set netout "$::unicode(arrow-up)[lindex [freebsd::getnetout $if_out] 0] "
}

proc zstatus::system::hide_memstats {} {
	variable memstats_visible
	set memstats_visible 0
	destroy .memstats
}

proc zstatus::system::show_memstats {} {
	variable memstats_visible
	variable memstats_text
	variable bartheme
	variable systheme
	variable sysfont

	set sysfont normal

	set memstats_visible 1
	set memstats [toplevel .memstats -highlightthickness 0\
				 -background $bartheme]
	wm title $memstats "Memory stats"
	wm attributes $memstats -type dialog
	wm overrideredirect $memstats 1

	set memstats_text [text $memstats.text -font $sysfont\
				-bd 0 -highlightthickness 0 -height 4]
	pack $memstats_text -side left -padx 5 -pady 3

	bind $memstats <Map> { zstatus::map_window .memstats }
	update_memstats
}

proc zstatus::system::update_memstats {} {
	variable memstats_visible
	variable memstats_text
	variable bartheme
	variable systheme

	if {!$memstats_visible} { return }

	set memstats [freebsd::getmemused]
	set current_text "Memory:\n Total: [lindex $memstats 0]"
	set current_text "$current_text\n Used: [lindex $memstats 1]"
	set current_text "$current_text\n Free: [lindex $memstats 2]"

	set width 0
	foreach line [split $current_text \n] {
		set width [tcl::mathfunc::max [string length $line] $width]
	}

	$memstats_text delete 1.0 end
	$memstats_text insert 1.0 $current_text
	$memstats_text configure -width $width -fg $systheme -bg $bartheme
}

proc zstatus::system::hide_netstat {} {
	variable netstat_visible
	set netstat_visible 0
	destroy .netstat
}

proc zstatus::system::show_netstat {} {
	variable netstat_visible
	variable netstat_text
	variable bartheme
	variable systheme
	variable sysfont

	set sysfont normal

	set netstat_visible 1
	set netstat [toplevel .netstat -highlightthickness 0\
				 -background $bartheme]
	wm title $netstat "Network status"
	wm attributes $netstat -type dialog
	wm overrideredirect $netstat 1

	set netstat_text [text $netstat.text -font $sysfont\
				-bd 0 -highlightthickness 0 -height 3]
	pack $netstat_text -side left -padx 5 -pady 3

	bind $netstat <Map> { zstatus::map_window .netstat }
	update_netstat
}

proc zstatus::system::update_netstat {} {
	variable netstat_visible
	variable netstat_text
	variable netstat_if
	variable systheme
	variable bartheme

	if {!$netstat_visible} { return }
	set netstat [freebsd::getnetstat $netstat_if]
	set ipaddr "IPv4: [lindex $netstat 0]"
	set netin "$::unicode(arrow-down) [lindex $netstat 1]"
	set netout "$::unicode(arrow-up) [lindex $netstat 2]"
	set current_text "Interface: $netstat_if \n$ipaddr \n$netin   $netout"

	set width 0
	foreach line [split $current_text \n] {
		set width [tcl::mathfunc::max [string length $line] $width]
	}

	$netstat_text delete 1.0 end
	$netstat_text insert 1.0 $current_text
	$netstat_text configure -width $width -fg $systheme -bg $bartheme
}

proc zstatus::system::set_mixer {} {
	variable mixer
	variable mixer_icon
	set mixer "$mixer_icon [freebsd::getmixervol]"
}

proc zstatus::system::setup {bar item} {
	switch $item {
	memused {
		bind $bar.memused <Enter> { zstatus::system::show_memstats }
		bind $bar.memused <Leave> { zstatus::system::hide_memstats }
	}
	mixer {
		variable mixer_icon
		set mixer_icon $::unicode(volume-up)
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
	netstat {
		variable netstat_icon
		set netstat_icon $::unicode(arrow-up-down)

		variable netstat_if
		set netstat_if [dict get $::widgetdict netstat interface]
		bind $bar.netstat <Enter> { zstatus::system::show_netstat }
		bind $bar.netstat <Leave> { zstatus::system::hide_netstat }
	}
	netin {
		variable if_in
		set if_in [dict get $::widgetdict netin interface]
	}
	netout {
		variable if_out
		set if_out [dict get $::widgetdict netout interface]
	}}

	if [dict exists $::widgetdict $item exec] {
		set command [dict get $::widgetdict $item exec]
		bind $bar.$item <1> "exec $command >/dev/null 2>@1 &"
	}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
