#!/usr/bin/env tclsh9.0
package require zstatus::system::freebsd

namespace eval zstatus::system {
	namespace export set_loadavg set_memused set_mixer

	variable locale C
	variable sysfont normal
	set syslocales {C fr}
	set lang [dict get $::config lang]
	set index [lsearch $syslocales [lindex [split $lang "_"] 0]]
	if {$index >= 0} {
		set locale [lindex $syslocales $index]
	}

	set sysdict [dict create\
		load {C "L:" fr "C:"}\
		memstats {C "MemStats" fr "MemStats"}\
		mem {C "RAM:" fr "RAM :"}\
		arc {C "ARC:" fr "ARC :"}\
		swap {C "Swao:" fr "Swap :"}\
		total {C "Total" fr "Total"}\
		used {C "Used" fr "Utilisé"}\
		free {C "Free" fr "Libre"}\
		ipv4 {C "IPv4:" fr "IPv4 :"}\
		ipv6 {C "IPv6:" fr "IPv6 :"}\
		trf {C "Transfers:" fr "Transferts :"}]

	array set linecolor { light DeepSkyBlue dark SeaGreen }

	variable loadgraph_visible 0
	variable memstats_visible 0
	variable netstat_visible 0

	variable load_queue {}
	variable load_length 180
}

proc zstatus::system::set_theme {theme} {
	variable bartheme
	variable systheme
	variable linecolor
	variable linetheme

	set bartheme [dict get $::widgetdict statusbar $theme]
	set linetheme $linecolor($theme)
	set systheme [dict get $::widgetdict loadavg $theme]

	variable loadgraph_visible
	if {$loadgraph_visible} { set_theme_loadgraph }
	variable memstats_visible
	if {$memstats_visible} { set_theme_memstats }
	variable netstat_visible
	if {$netstat_visible} { set_theme_netstat }
}

proc zstatus::system::set_theme_loadgraph {} {
	variable loadgraph
	variable bartheme
	$loadgraph configure -bg $bartheme
	update_loadgraph
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
	$memgrid.mem_free configure -bg $bartheme -fg $systheme
	$memgrid.mem_total configure -bg $bartheme -fg $systheme
	$memgrid.arc configure -bg $bartheme -fg $systheme
	$memgrid.arc_used configure -bg $bartheme -fg $systheme
	$memgrid.arc_free configure -bg $bartheme -fg $systheme
	$memgrid.arc_total configure -bg $bartheme -fg $systheme
	$memgrid.swap configure -bg $bartheme -fg $systheme
	$memgrid.swap_used configure -bg $bartheme -fg $systheme
	$memgrid.swap_free configure -bg $bartheme -fg $systheme
	$memgrid.swap_total configure -bg $bartheme -fg $systheme
}

proc zstatus::system::set_theme_netstat {} {
	variable systheme
	variable bartheme
	variable netgrid

	.netstat configure -background $bartheme
	$netgrid configure -background $bartheme
	$netgrid.ipv4 configure -bg $bartheme -fg $systheme
	$netgrid.ipv4_addr configure -bg $bartheme -fg $systheme
	$netgrid.ipv6 configure -bg $bartheme -fg $systheme
	$netgrid.ipv6_addr configure -bg $bartheme -fg $systheme
	$netgrid.transfer configure -bg $bartheme -fg $systheme
	$netgrid.transfer_val configure -bg $bartheme -fg $systheme
}

proc zstatus::system::set_loadavg {} {
	variable loadavg
	variable sysdict
	variable locale
	variable load_queue
	variable load_length

	set value [freebsd::getloadavg]
	lappend load_queue $value
	if {[llength $load_queue] > $load_length} {
		set load_queue [lrange $load_queue 1 end]
	}
	set loadavg "[dict get $sysdict load $locale] $value"

	variable loadgraph_visible
	if {$loadgraph_visible} { update_loadgraph }
}

proc zstatus::system::hide_loadgraph {} {
	variable loadgraph_visible
	set loadgraph_visible 0
	destroy .loadgraph
}

proc zstatus::system::show_loadgraph {} {
	variable bartheme
	variable systheme
	variable sysfont
	variable barwidget
	variable loadwidget
	variable loadgraph
	variable loadgraph_visible

	set loadgraph_visible 1
	set loadframe [toplevel .loadgraph -highlightthickness 0\
				 -background $bartheme]

	set xpos [winfo x $loadwidget]
	set ypos [expr [winfo y $barwidget] + [winfo height $barwidget] + 1]
	wm title $loadframe "Load average"
	wm attributes $loadframe -type dialog
	wm overrideredirect $loadframe 1
	wm geometry $loadframe +$xpos+$ypos

	set loadgraph $loadframe.graphics
	pack [canvas $loadgraph -width 180 -height 60 -highlightthickness 0 -bg $bartheme]
	update_loadgraph
}

proc zstatus::system::update_loadgraph {} {
	variable bartheme
	variable linetheme
	variable systheme
	variable loadgraph
	variable load_queue

	set ymax 1
	foreach value $load_queue {
		if {$value > $ymax} { incr ymax }
	}
	set xpos 1
	foreach value $load_queue {
		set ypos [tcl::mathfunc::round [expr 60 * ($ymax - $value) / $ymax]]
		$loadgraph create line $xpos 60 $xpos $ypos -fill $linetheme
		incr xpos
	}
	set hline 1
	while {$hline < $ymax} {
		set ypos [tcl::mathfunc::round [expr 60 * ($ymax - $hline) / $ymax ]]
		$loadgraph create line 1 $ypos 180 $ypos -fill $systheme
		incr hline
	}
}

proc zstatus::system::set_memused {} {
	variable memused
	set memused "M: [lindex [freebsd::getpercmemused] 0]"

	variable memstats_visible
	if {$memstats_visible} { update_memstats }
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
	variable netgrid
	variable bartheme
	variable systheme
	variable sysfont
	variable sysdict
	variable locale
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

	set netgrid $netstat.grid

	set row 0
	pack [frame $netgrid -background $bartheme] -padx 5 -pady 5 -side top -anchor w
	label $netgrid.ipv4 -font $sysfont -text [dict get $sysdict ipv4 $locale]\
		-bg $bartheme -fg $systheme
	grid configure $netgrid.ipv4 -row $row -column 0 -sticky w
	label $netgrid.ipv4_addr -font $sysfont -bg $bartheme -fg $systheme
	grid configure $netgrid.ipv4_addr -row $row -column 1 -sticky e

	incr row
	label $netgrid.ipv6 -font $sysfont -text [dict get $sysdict ipv6 $locale]\
		-bg $bartheme -fg $systheme
	grid configure $netgrid.ipv6 -row $row -column 0 -sticky w
	label $netgrid.ipv6_addr -font $sysfont -bg $bartheme -fg $systheme
	grid configure $netgrid.ipv6_addr -row $row -column 1 -sticky e

	incr row
	label $netgrid.transfer -font $sysfont -text [dict get $sysdict trf $locale]\
		-bg $bartheme -fg $systheme
	grid configure $netgrid.transfer -row $row -column 0 -sticky w
	label $netgrid.transfer_val -font $sysfont -bg $bartheme -fg $systheme
	grid configure $netgrid.transfer_val -row $row -column 1 -sticky e

	grid columnconfigure $netgrid 0 -pad 5
	grid columnconfigure $netgrid 1 -pad 5

	bind $netstat <Map> { zstatus::map_window .netstat }
	update_netstat
}

proc zstatus::system::update_netstat {} {
	variable netstat_visible
	if {!$netstat_visible} { return }

	variable netstat_if
	variable netgrid

	set netstat [freebsd::getnetstat $netstat_if]
	set netin "$::unicode(arrow-down) [lindex $netstat 2]"
	set netout "$::unicode(arrow-up) [lindex $netstat 3]"
	$netgrid.ipv4_addr configure -text [lindex $netstat 0]
	$netgrid.ipv6_addr configure -text [lindex $netstat 1]
	$netgrid.transfer_val configure -text "$netin   $netout"
}

proc zstatus::system::set_mixer {} {
	variable mixer
	variable mixer_icon
	set mixer "$mixer_icon [freebsd::getmixervol]"
}

proc zstatus::system::setup {bar item} {
	variable barwidget
	variable loadwidget
	variable memwidget
	variable netwidget

	switch $item {
	loadavg {
		set barwidget $bar
		set loadwidget $bar.$item
		bind $loadwidget <Enter> { zstatus::system::show_loadgraph }
		bind $loadwidget <Leave> { zstatus::system::hide_loadgraph }
	}
	memused {
		set barwidget $bar
		set memwidget $bar.$item
		bind $memwidget <Enter> { zstatus::system::show_memstats }
		bind $memwidget <Leave> { zstatus::system::hide_memstats }
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

		variable netstat_if
		set netstat_if [dict get $::widgetdict netstat interface]
		variable interface
		#set interface "$::unicode(arrow-up-down) $netstat_if"
		set interface "E: $netstat_if"

		bind $netwidget <Enter> { zstatus::system::show_netstat }
		bind $netwidget <Leave> { zstatus::system::hide_netstat }
	}}

	if [dict exists $::widgetdict $item exec] {
		set command [dict get $::widgetdict $item exec]
		bind $bar.$item <1> "exec $command >/dev/null 2>@1 &"
	}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
