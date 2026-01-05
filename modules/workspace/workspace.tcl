#!/usr/bin/env wish9.0
namespace eval zstatus::workspace {
	array set modes {Monocle M VTiled V HTiled H Stacked S}
	namespace export set_wintitle unset_wintitle set_wslist set_wsname\
			set_wsmode set_theme

	variable screen [lindex [split [winfo screen .] "."] 1]
	variable zwmsocket "[dict get $::config cache_prefix]/zwm/socket"
}

proc zstatus::workspace::send_message {msg} {
	variable screen
	variable zwmsocket

	if [catch {set channel [unix_sockets::connect $zwmsocket]}] {
		puts stderr "Could not open socket $zwmsocket!\n"
		return
	}
	puts $channel "$screen;$msg"
	close $channel
}

proc zstatus::workspace::set_theme {theme} {
	variable bartheme
	variable wslisttheme
	variable wslistbar
	variable wslistframe

	set bartheme [dict get $::color background $theme]
	set wslisttheme [dict get $::widgetdict wslist $theme]

	$wslistbar configure -background $bartheme
	$wslistframe configure -background $bartheme
	foreach slave [pack slaves $wslistframe] {
		$slave configure -bg $bartheme -fg $wslisttheme
	}
}

proc zstatus::workspace::set_wintitle {value} {
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

proc zstatus::workspace::unset_wintitle {value} {
	variable wintitle
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -state disabled
}

proc zstatus::workspace::set_wslist {value} {
	variable bartheme
	variable wslisttheme
	variable wslistbar
	variable wslistframe

	destroy $wslistframe
	pack [frame $wslistframe]
	$wslistbar configure -background $bartheme
	$wslistframe configure -background $bartheme

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
		pack [label $slave -font $font -text "$name" -padx 2] -side left

		$slave configure -bg $bartheme -fg $wslisttheme
		if {$active} {
			continue
		}

		bind $slave <1> "zstatus::workspace::send_message desktop-switch-$num"
	}
}

proc zstatus::workspace::set_wsmode {value} {
	variable modes
	variable wsmode
	if [info exists modes($value)] {
		set wsmode " $modes($value)"
	} else {
		set wsmode " $value"
	}
}

proc zstatus::workspace::set_wsname {value} {
	variable wsname
	set wsname $value
}

proc zstatus::workspace::setup {bar item} {
	switch $item {
	wintitle {
		dict set ::messagedict window_active\
				{action workspace::set_wintitle arg 1}
		dict set ::messagedict no_window_active\
				{action workspace::unset_wintitle arg 1}
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
		dict set ::messagedict ws_mode {action workspace::set_wsmode arg 1}
		bind $bar.wsmode <MouseWheel> {
			if {%D < 0} {
				zstatus::workspace::send_message "desktop-mode-next"
			} else {
				zstatus::workspace::send_message "desktop-mode-prev"
			}
		}
	}
	wslist {
		dict set ::messagedict ws_list {action workspace::set_wslist arg 1}
		variable wslistbar
		variable wslistframe
		set wslistbar [frame $bar.$item]
		set wslistframe [frame $wslistbar.frame]
		pack $wslistbar
		pack $wslistframe
	}
	wsname {
		dict set ::messagedict ws_name {action workspace::set_wsname arg 1}
	}}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
