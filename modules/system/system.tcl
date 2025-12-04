#!/usr/bin/env tclsh9.0
package require zstatus::system::freebsd

namespace eval zstatus::system {
	namespace export set_loadavg set_memused set_arcsize set_netin set_netout\
		 set_mixer

	set syslocales {C fr}
	set sysdict [dict create\
		load {C "L:" fr "C:"}\
		memstats {C "MemStats" fr "MemStats"}\
		mem {C "RAM:" fr "RAM :"}\
		arc {C "ARC:" fr "ARC :"}\
		swap {C "Swao:" fr "Swap :"}\
		total {C "Total" fr "Total"}\
		used {C "Used" fr "Utilisé"}\
		free {C "Free" fr "Libre"}]

	variable memstats_visible 0
	variable netstat_visible 0
}

proc zstatus::system::set_theme {theme} {
	variable memstats_visible
	variable netstat_visible
	variable systheme
	variable bartheme
	set bartheme [dict get $::widgetdict statusbar $theme]
	set systheme [dict get $::widgetdict netstat $theme]
	if {$memstats_visible} { set_theme_memstats }
	if {$netstat_visible} { set_theme_netstat }
}

proc zstatus::system::set_theme_memstats {} {
	variable systheme
	variable bartheme
	variable memgrid
	.memstats configure -background $bartheme
	$memgrid configure -background $bartheme
	$memgrid.used configure -bg $bartheme -fg $systheme
	$memgrid.total configure -bg $bartheme -fg $systheme
	$memgrid.memory configure -bg $bartheme -fg $systheme
	$memgrid.mem_used configure -bg $bartheme -fg $systheme
	$memgrid.mem_total configure -bg $bartheme -fg $systheme
	$memgrid.arc configure -bg $bartheme -fg $systheme
	$memgrid.arc_used configure -bg $bartheme -fg $systheme
	$memgrid.arc_total configure -bg $bartheme -fg $systheme
	$memgrid.swap configure -bg $bartheme -fg $systheme
	$memgrid.swap_used configure -bg $bartheme -fg $systheme
	$memgrid.swap_total configure -bg $bartheme -fg $systheme
}

proc zstatus::system::set_theme_netstat {} {
	variable systheme
	variable bartheme
	.netstat configure -background $bartheme
	.netstat.text configure -fg $systheme -bg $bartheme
}

proc zstatus::system::set_loadavg {} {
	variable loadavg
	variable sysdict
	variable locale
	set loadavg "[dict get $sysdict load $locale][freebsd::getloadavg] "
}

proc zstatus::system::set_memused {} {
	variable memused
	set memused "M: [lindex [freebsd::getpercmemused] 0] "
	update_memstats
}

proc zstatus::system::set_arcsize {} {
	variable arcsize
	set arcsize "ARC: [lindex [freebsd::getarcstats] 1] "
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
	variable sysdict
	variable locale
	variable bartheme
	variable systheme
	variable sysfont
	variable barwidget
	variable memwidget
	variable memgrid

	set memstats_visible 1
	set memstats [toplevel .memstats -highlightthickness 0\
				 -background $bartheme]

	set xpos [winfo x $memwidget]
	set ypos [expr [winfo y $barwidget] + [winfo height $barwidget] + 1]
	wm title $memstats "Memory stats"
	wm attributes $memstats -type dialog
	wm overrideredirect $memstats 1
	wm geometry $memstats +$xpos+$ypos

	set memgrid $memstats.grid

	set row 0
	pack [frame $memgrid -background $bartheme] -padx 5 -pady 5 -side top -anchor w
	label $memgrid.title -font $sysfont -text [dict get $sysdict memstats $locale]\
		-bg $bartheme -fg $systheme
	grid configure $memgrid.title -row $row -column 0 -sticky w
	label $memgrid.used -font $sysfont  -text [dict get $sysdict used $locale]\
		-bg $bartheme -fg $systheme
	grid configure $memgrid.used -row $row -column 1 -sticky e
	label $memgrid.free -font $sysfont -text [dict get $sysdict free $locale]\
		 -bg $bartheme -fg $systheme
	grid configure $memgrid.free -row $row -column 2 -sticky e
	label $memgrid.total -font $sysfont -text [dict get $sysdict total $locale]\
		-bg $bartheme -fg $systheme
	grid configure $memgrid.total -row $row -column 3 -sticky e
	incr row
	label $memgrid.memory -font $sysfont -text [dict get $sysdict mem $locale]\
		-bg $bartheme -fg $systheme
	grid configure $memgrid.memory -row $row -column 0 -sticky w
	label $memgrid.mem_used -font $sysfont -bg $bartheme -fg $systheme
	grid configure $memgrid.mem_used -row $row -column 1 -sticky e
	label $memgrid.mem_free -font $sysfont -bg $bartheme -fg $systheme
	grid configure $memgrid.mem_free -row $row -column 2 -sticky e
	label $memgrid.mem_total -font $sysfont -bg $bartheme -fg $systheme
	grid configure $memgrid.mem_total -row $row -column 3 -sticky e
	incr row
	label $memgrid.arc -font $sysfont -text [dict get $sysdict arc $locale]\
		-bg $bartheme -fg $systheme
	grid configure $memgrid.arc -row $row -column 0 -sticky w
	label $memgrid.arc_used -font $sysfont -bg $bartheme -fg $systheme
	grid configure $memgrid.arc_used -row $row -column 1 -sticky e
	label $memgrid.arc_free -font $sysfont -bg $bartheme -fg $systheme
	grid configure $memgrid.arc_free -row $row -column 2 -sticky e
	label $memgrid.arc_total -font $sysfont -bg $bartheme -fg $systheme
	grid configure $memgrid.arc_total -row $row -column 3 -sticky e
	incr row
	label $memgrid.swap -font $sysfont -text [dict get $sysdict swap $locale]\
		 -bg $bartheme -fg $systheme
	grid configure $memgrid.swap -row $row -column 0 -sticky w
	label $memgrid.swap_used -font $sysfont -bg $bartheme -fg $systheme
	grid configure $memgrid.swap_used -row $row -column 1 -sticky e
	label $memgrid.swap_free -font $sysfont -bg $bartheme -fg $systheme
	grid configure $memgrid.swap_free -row $row -column 2 -sticky e
	label $memgrid.swap_total -font $sysfont -bg $bartheme -fg $systheme
	grid configure $memgrid.swap_total -row $row -column 3 -sticky e

	grid columnconfigure $memgrid 0 -pad 5
	grid columnconfigure $memgrid 1 -pad 5
	grid columnconfigure $memgrid 2 -pad 5
	grid columnconfigure $memgrid 3 -pad 5

	bind $memstats <Map> { zstatus::map_window .memstats }
	update_memstats
}

proc zstatus::system::update_memstats {} {
	variable memstats_visible
	if {!$memstats_visible} { return }

	variable memgrid
	variable bartheme
	variable systheme

	set memstats [freebsd::getmemused]
	$memgrid.mem_total configure -text [lindex $memstats 0]
	$memgrid.mem_used configure -text [lindex $memstats 1]
	$memgrid.mem_free configure -text [lindex $memstats 2]
	set arcstats [freebsd::getarcstats]
	$memgrid.arc_total configure -text [lindex $arcstats 0]
	$memgrid.arc_used configure -text [lindex $arcstats 1]
	$memgrid.arc_free configure -text [lindex $arcstats 2]
	set swapinfo [freebsd::getswapinfo]
	$memgrid.swap_total configure -text [lindex $swapinfo 0]
	$memgrid.swap_used configure -text [lindex $swapinfo 1]
	$memgrid.swap_free configure -text [lindex $swapinfo 2]
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
	variable barwidget
	variable netwidget

	set netstat_visible 1
	set netstat [toplevel .netstat -highlightthickness 0\
				 -background $bartheme]

	set xpos [winfo x $netwidget]
	set ypos [expr [winfo y $barwidget] + [winfo height $barwidget] + 1]
	wm title $netstat "Network status"
	wm attributes $netstat -type dialog
	wm overrideredirect $netstat 1
	wm geometry $netstat +$xpos+$ypos

	set netstat_text [text $netstat.text -font $sysfont\
				-fg $systheme -bg $bartheme\
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
	$netstat_text configure -width $width
}

proc zstatus::system::set_mixer {} {
	variable mixer
	variable mixer_icon
	set mixer "$mixer_icon [freebsd::getmixervol]"
}

proc zstatus::system::init {} {
	variable syslocales
	variable locale
	variable sysfont

	set sysfont normal
	set lang [dict get $::config lang]
	set index [lsearch $syslocales [lindex [split $lang "_"] 0]]
	if {$index < 0} {
		set locale C
	} else {
		set locale [lindex $syslocales $index]
	}
}

proc zstatus::system::setup {bar item} {
	variable barwidget
	variable memwidget
	variable netwidget

	switch $item {
	memused {
		set barwidget $bar
		set memwidget $bar.$item
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
		set barwidget $bar
		set netwidget $bar.$item
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
