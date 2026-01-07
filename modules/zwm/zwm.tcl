#!/usr/bin/env wish9.0
namespace eval zstatus::zwm {
	array set modes {Monocle M VTiled V HTiled H Stacked S}
	namespace export set_wintitle unset_wintitle set_wslist set_wsname\
			set_wsmode set_theme

	variable screen [lindex [split [winfo screen .] "."] 1]
	variable zwmsocket "[dict get $::config cache_prefix]/zwm/socket"
}

proc zstatus::zwm::send_message {msg} {
	variable screen
	variable zwmsocket

	if [catch {set channel [unix_sockets::connect $zwmsocket]}] {
		puts stderr "Could not open socket $zwmsocket!\n"
		return
	}
	puts $channel "$screen;$msg"
	close $channel
}

proc zstatus::zwm::set_theme {theme} {
	variable bgcolor
	variable fgcolor
	variable hicolor
	variable wslistbar
	variable wslistframe
	variable activeslave

	set bgcolor [dict get $::widgetdict wslist bg $theme]
	set fgcolor [dict get $::widgetdict wslist fg $theme]
	set hicolor [dict get $::color highlight $theme]

	$wslistbar configure -background $bgcolor
	$wslistframe configure -background $bgcolor
	foreach slave [pack slaves $wslistframe] {
		if {$slave == $activeslave} {
			$slave configure -bg $hicolor -fg $fgcolor
		} else {
			$slave configure -bg $bgcolor -fg $fgcolor
		}
	}
}

proc zstatus::zwm::set_wintitle {value} {
	set maxlength [dict get $::widgetdict wintitle maxlength]
	set length [tcl::mathfunc::min [string length $value] $maxlength]
	variable wintitle
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -width $length
	$wintitle insert 1.0 $value

	variable emojis
	if {$emojis} {
		foreach e [$wintitle search -all \
			-regexp {[\u2000-\u28ff\U1f000-\U1faff]} 1.0 end] {
			$wintitle tag add emoji $e
		}
	}
	$wintitle configure -state disabled
}

proc zstatus::zwm::unset_wintitle {value} {
	variable wintitle
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -state disabled
}

proc zstatus::zwm::set_wslist {value} {
	variable bgcolor
	variable fgcolor
	variable hicolor
	variable wslistbar
	variable wslistframe
	variable activeslave

	destroy $wslistframe
	pack [frame $wslistframe]
	$wslistbar configure -background $bgcolor
	$wslistframe configure -background $bgcolor

	foreach name [split $value "|"] {
		if {![string length $name]} {
			continue
		}
		set active 0
		set first [string index $name 0]
		set font normal
		if {$first == "+"} {
			set num [string range $name 1 end]
			set font bold
			set active 1
		} elseif {$first == "!"} {
			set num [string range $name 1 end]
			set font italic
		} else {
			set num $name
		}

		set slave $wslistframe.$num
		pack [label $slave -font $font -text $num] -padx 0 -ipadx 4 -side left

		if {$active} {
			set activeslave $slave
			$slave configure -bg $hicolor -fg $fgcolor
			continue
		}
		$slave configure -bg $bgcolor -fg $fgcolor

		bind $slave <1> "zstatus::zwm::send_message desktop-switch-$num"
	}
}

proc zstatus::zwm::set_wsmode {value} {
	variable modes
	variable wsmode
	if [info exists modes($value)] {
		set wsmode " $modes($value)"
	} else {
		set wsmode " $value"
	}
}

proc zstatus::zwm::set_wsname {value} {
	variable wsname
	set wsname $value
}

proc zstatus::zwm::setup {bar item} {
	switch $item {
	wintitle {
		dict set ::messagedict window_active\
				{action zwm::set_wintitle arg 1}
		dict set ::messagedict no_window_active\
				{action zwm::unset_wintitle arg 1}
		variable wintitle
		set wintitle [text $bar.$item\
			-font [dict get $::widgetdict wintitle font]\
			-height 1 -borderwidth 0\
			-highlightthickness 0 -wrap word]

		variable emojis
		set emojis 0
		if {[lsearch [font names] emoji] != -1} {
			set emojis 1
			$wintitle tag configure emoji -font emoji
		}
		$wintitle configure -state disabled
	}
	wsmode {
		dict set ::messagedict ws_mode {action zwm::set_wsmode arg 1}
		bind $bar.wsmode <MouseWheel> {
			if {%D < 0} {
				zstatus::zwm::send_message "desktop-mode-next"
			} else {
				zstatus::zwm::send_message "desktop-mode-prev"
			}
		}
	}
	wslist {
		dict set ::messagedict ws_list {action zwm::set_wslist arg 1}
		variable wslistbar
		variable wslistframe
		set wslistbar [frame $bar.$item]
		set wslistframe [frame $wslistbar.frame]
		pack $wslistbar
		pack $wslistframe
	}
	wsname {
		dict set ::messagedict ws_name {action zwm::set_wsname arg 1}
	}}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
