package require zstatus::system::freebsd

namespace eval zstatus::system {
	namespace export set_loadavg set_memused set_mixer

	variable locale C
	set syslocales {C fr}
	set lang [dict get $::config lang]
	set index [lsearch $syslocales [lindex [split $lang "_"] 0]]
	if {$index >= 0} {
		set locale [lindex $syslocales $index]
	}

	set sysdict [dict create\
		memstats {C "Memory" fr "Mémoire"}\
		mem {C "RAM:" fr "RAM :"}\
		arc {C "ARC:" fr "ARC :"}\
		swap {C "Swao:" fr "Swap :"}\
		total {C "Total" fr "Total"}\
		used {C "Used" fr "Utilisé"}\
		free {C "Free" fr "Libre"}\
		interface {C "Interface:" fr "Interface :"}\
		ipv4 {C "IPv4:" fr "IPv4 :"}\
		ipv6 {C "IPv6:" fr "IPv6 :"}\
		trf {C "Transfers:" fr "Transferts :"}]

	variable loadgraph_visible 0
	variable memstats_visible 0
	variable netstat_visible 0

	variable load_queue {}
	variable load_length 210
	variable load_height 80
}

proc zstatus::system::set_theme {theme} {
	variable bgcolor
	variable fgcolor
	variable linecolor

	set bgcolor [dict get $::color bg $theme]
	set fgcolor [dict get $::color fg $theme]
	set linecolor [dict get $::color line $theme]

	variable loadgraph_visible
	if {$loadgraph_visible} { set_theme_loadgraph }
	variable memstats_visible
	if {$memstats_visible} { set_theme_memstats }
	variable netstat_visible
	if {$netstat_visible} { set_theme_netstat }
}

proc zstatus::system::set_theme_loadgraph { } {
	variable loadgraph
	variable bgcolor
	$loadgraph configure -bg $bgcolor
	update_loadgraph
}

proc zstatus::system::set_theme_memstats { } {
	variable bgcolor
	variable fgcolor
	variable memgrid

	.memstats configure -background $bgcolor
	$memgrid configure -background $bgcolor
	$memgrid.title configure -bg $bgcolor -fg $fgcolor
	$memgrid.used configure -bg $bgcolor -fg $fgcolor
	$memgrid.free configure -bg $bgcolor -fg $fgcolor
	$memgrid.total configure -bg $bgcolor -fg $fgcolor
	$memgrid.memory configure -bg $bgcolor -fg $fgcolor
	$memgrid.mem_used configure -bg $bgcolor -fg $fgcolor
	$memgrid.mem_free configure -bg $bgcolor -fg $fgcolor
	$memgrid.mem_total configure -bg $bgcolor -fg $fgcolor
	$memgrid.arc configure -bg $bgcolor -fg $fgcolor
	$memgrid.arc_used configure -bg $bgcolor -fg $fgcolor
	$memgrid.arc_free configure -bg $bgcolor -fg $fgcolor
	$memgrid.arc_total configure -bg $bgcolor -fg $fgcolor
	$memgrid.swap configure -bg $bgcolor -fg $fgcolor
	$memgrid.swap_used configure -bg $bgcolor -fg $fgcolor
	$memgrid.swap_free configure -bg $bgcolor -fg $fgcolor
	$memgrid.swap_total configure -bg $bgcolor -fg $fgcolor
}

proc zstatus::system::set_theme_netstat { } {
	variable bgcolor
	variable fgcolor
	variable netgrid
	set fgcolor [dict $::widgetdict netstat fg $theme]

	.netstat configure -background $bgcolor
	$netgrid configure -background $bgcolor
	$netgrid.ipv4 configure -bg $bgcolor -fg $fgcolor
	$netgrid.ipv4_addr configure -bg $bgcolor -fg $fgcolor
	$netgrid.ipv6 configure -bg $bgcolor -fg $fgcolor
	$netgrid.ipv6_addr configure -bg $bgcolor -fg $fgcolor
	$netgrid.transfer configure -bg $bgcolor -fg $fgcolor
	$netgrid.transfer_val configure -bg $bgcolor -fg $fgcolor
}

proc zstatus::system::set_loadavg {} {
	variable loadavg
	variable load_queue
	variable load_length

	set value [freebsd::getloadavg]
	lappend load_queue $value
	if {[llength $load_queue] > $load_length} {
		set load_queue [lrange $load_queue 1 end]
	}
	set loadavg "$::unicode(bar-chart) $value"

	variable loadgraph_visible
	if {$loadgraph_visible} { update_loadgraph }
}

proc zstatus::system::hide_loadgraph {} {
	variable loadgraph_visible
	set loadgraph_visible 0
	destroy .loadframe
}

proc zstatus::system::show_loadgraph {} {
	variable bgcolor
	variable barwidget
	variable loadwidget
	variable loadgraph
	variable loadgraph_visible
	variable load_length
	variable load_height

	set loadgraph_visible 1
	set loadframe [toplevel .loadframe -highlightthickness 0\
				 -background $bgcolor]

	set xpos [winfo rootx $loadwidget]
	set ypos [expr [winfo rooty $barwidget] + [winfo height $barwidget] + 1]
	wm title $loadframe "Load average"
	wm attributes $loadframe -type dialog
	wm overrideredirect $loadframe 1
	wm geometry $loadframe +$xpos+$ypos

	set loadgraph $loadframe.graphics
	pack [canvas $loadgraph -width $load_length -height $load_height\
		 -highlightthickness 0 -bg $bgcolor]

	bind $loadframe <Map> { zstatus::map_window .loadframe }
	update_loadgraph
}

proc zstatus::system::update_loadgraph {} {
	variable bgcolor
	variable fgcolor
	variable linecolor
	variable loadgraph
	variable load_queue
	variable load_length
	variable load_height

	set ymax 1
	foreach value $load_queue {
		if {$value > $ymax} { incr ymax }
	}
	set xpos 1
	foreach value $load_queue {
		set ypos [tcl::mathfunc::round [expr 1.0 * $load_height *\
				($ymax - $value) / $ymax]]
		$loadgraph create line $xpos $load_height $xpos $ypos -fill $linecolor
		incr xpos
	}
	set hline 1
	while {$hline < $ymax} {
		set ypos [tcl::mathfunc::round [expr 1.0 * $load_height *\
				($ymax - $hline) / $ymax ]]
		$loadgraph create line 1 $ypos $load_length $ypos -fill $fgcolor
		incr hline
	}
}

proc zstatus::system::set_memused {} {
	variable memused
	set memused "$::unicode(ram) [lindex [freebsd::getpercmemused] 0]"

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
	variable bgcolor
	variable fgcolor
	variable barwidget
	variable memwidget
	variable memgrid

	set memstats_visible 1
	set memstats [toplevel .memstats -highlightthickness 0\
				 -background $bgcolor]

	set xpos [winfo rootx $memwidget]
	set ypos [expr [winfo rooty $barwidget] + [winfo height $barwidget] + 1]
	wm title $memstats "Memory stats"
	wm attributes $memstats -type dialog
	wm overrideredirect $memstats 1
	wm geometry $memstats +$xpos+$ypos

	set memgrid $memstats.grid

	set row 0
	pack [frame $memgrid -background $bgcolor] -padx 5 -pady 5 -side top -anchor w
	label $memgrid.title -font bold -text [dict get $sysdict memstats $locale]\
		-bg $bgcolor -fg $fgcolor
	grid configure $memgrid.title -row $row -column 0 -sticky w
	label $memgrid.used -font bold  -text [dict get $sysdict used $locale]\
		-bg $bgcolor -fg $fgcolor
	grid configure $memgrid.used -row $row -column 1 -sticky e
	label $memgrid.free -font bold -text [dict get $sysdict free $locale]\
		 -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.free -row $row -column 2 -sticky e
	label $memgrid.total -font bold -text [dict get $sysdict total $locale]\
		-bg $bgcolor -fg $fgcolor
	grid configure $memgrid.total -row $row -column 3 -sticky e
	incr row
	label $memgrid.memory -font bold -text [dict get $sysdict mem $locale]\
		-bg $bgcolor -fg $fgcolor
	grid configure $memgrid.memory -row $row -column 0 -sticky w
	label $memgrid.mem_used -font normal -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.mem_used -row $row -column 1 -sticky e
	label $memgrid.mem_free -font normal -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.mem_free -row $row -column 2 -sticky e
	label $memgrid.mem_total -font normal -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.mem_total -row $row -column 3 -sticky e
	incr row
	label $memgrid.arc -font bold -text [dict get $sysdict arc $locale]\
		-bg $bgcolor -fg $fgcolor
	grid configure $memgrid.arc -row $row -column 0 -sticky w
	label $memgrid.arc_used -font normal -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.arc_used -row $row -column 1 -sticky e
	label $memgrid.arc_free -font normal -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.arc_free -row $row -column 2 -sticky e
	label $memgrid.arc_total -font normal -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.arc_total -row $row -column 3 -sticky e
	incr row
	label $memgrid.swap -font bold -text [dict get $sysdict swap $locale]\
		 -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.swap -row $row -column 0 -sticky w
	label $memgrid.swap_used -font normal -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.swap_used -row $row -column 1 -sticky e
	label $memgrid.swap_free -font normal -bg $bgcolor -fg $fgcolor
	grid configure $memgrid.swap_free -row $row -column 2 -sticky e
	label $memgrid.swap_total -font normal -bg $bgcolor -fg $fgcolor
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
	variable bgcolor
	variable fgcolor

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
	variable bgcolor
	variable fgcolor
	variable sysdict
	variable locale
	variable barwidget
	variable netwidget
	variable netstat_if

	set netstat_visible 1
	set netstat [toplevel .netstat -highlightthickness 0\
				 -background $bgcolor]

	set xpos [winfo rootx $netwidget]
	set ypos [expr [winfo rooty $barwidget] + [winfo height $barwidget] + 1]
	wm title $netstat "Network status"
	wm attributes $netstat -type dialog
	wm overrideredirect $netstat 1
	wm geometry $netstat +$xpos+$ypos

	set netgrid $netstat.grid

	set row 0
	pack [frame $netgrid -background $bgcolor] -padx 5 -pady 5 -side top -anchor w
	label $netgrid.interface -font bold -text [dict get $sysdict interface $locale]\
		-bg $bgcolor -fg $fgcolor
	grid configure $netgrid.interface -row $row -column 0 -sticky w
	label $netgrid.interface_val -font normal -text $netstat_if\
		 -bg $bgcolor -fg $fgcolor
	grid configure $netgrid.interface_val -row $row -column 1 -sticky e

	incr row
	label $netgrid.ipv4 -font bold -text [dict get $sysdict ipv4 $locale]\
		-bg $bgcolor -fg $fgcolor
	grid configure $netgrid.ipv4 -row $row -column 0 -sticky w
	label $netgrid.ipv4_addr -font normal -bg $bgcolor -fg $fgcolor
	grid configure $netgrid.ipv4_addr -row $row -column 1 -sticky e

	incr row
	label $netgrid.ipv6 -font bold -text [dict get $sysdict ipv6 $locale]\
		-bg $bgcolor -fg $fgcolor
	grid configure $netgrid.ipv6 -row $row -column 0 -sticky w
	label $netgrid.ipv6_addr -font normal -bg $bgcolor -fg $fgcolor
	grid configure $netgrid.ipv6_addr -row $row -column 1 -sticky e

	incr row
	label $netgrid.transfer -font bold -text [dict get $sysdict trf $locale]\
		-bg $bgcolor -fg $fgcolor
	grid configure $netgrid.transfer -row $row -column 0 -sticky w
	label $netgrid.transfer_val -font normal -bg $bgcolor -fg $fgcolor
	grid configure $netgrid.transfer_val -row $row -column 1 -sticky e

	grid columnconfigure $netgrid 0 -pad 5
	grid columnconfigure $netgrid 1 -pad 5

	bind $netstat <Map> { zstatus::map_window .netstat }
	update_netstat
}

proc zstatus::system::update_netstat {} {
	variable neticon
	variable netstat_if
	set netinfo [freebsd::getnetstat $netstat_if]
	set neticon "$::unicode(arrow-down)[lindex $netinfo 2]"

	variable netstat_visible
	if {!$netstat_visible} { return }

	variable netgrid
	$netgrid.ipv4_addr configure -text [lindex $netinfo 0]
	$netgrid.ipv6_addr configure -text [lindex $netinfo 1]
	set netin "$::unicode(arrow-down) [lindex $netinfo 2]"
	set netout "$::unicode(arrow-up) [lindex $netinfo 3]"
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

		bind $netwidget <Enter> { zstatus::system::show_netstat }
		bind $netwidget <Leave> { zstatus::system::hide_netstat }
	}}

	if [dict exists $::widgetdict $item exec] {
		set command [dict get $::widgetdict $item exec]
		bind $bar.$item <1> "exec $command >/dev/null 2>@1 &"
	}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
