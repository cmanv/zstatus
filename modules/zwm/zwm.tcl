namespace eval zstatus::zwm {
	variable layouts [dict create\
		Monocle	$::unicode(rectangle)\
		VTiled	$::unicode(layout-column)\
		HTiled	$::unicode(layout-row)\
		Stacked	$::unicode(file-copy)]

	dict set ::messagedict clientlist {action zwm::set_clientlist arg 1}
	dict set ::messagedict clientmenu {action zwm::clientmenu arg 0}

	variable screen [lindex [split [winfo screen .] "."] 1]
	variable zwmsocket "[dict get $::config cache_prefix]/zwm/socket"

	variable clientlist {}
	variable desklist "+?"
	variable desklayout "?"
	variable wintext ""
	variable winmaxlen [dict get $::widgetdict wintitle maxlength]
	variable theme_defined 0

	namespace export set_wintitle unset_wintitle set_desklist set_deskname\
			set_desklayout set_theme
}

proc zstatus::zwm::send_message {msg} {
	variable screen
	variable zwmsocket

	if [catch {set channel [unix_sockets::connect $zwmsocket]}] {
		puts stderr "Could not open socket $zwmsocket!\n"
		return
	}
	puts $channel "$screen:$msg"
	close $channel
}

proc zstatus::zwm::set_theme {theme} {
	variable desklistbar
	variable desklistframe
	variable activeslave
	variable theme_defined

	variable fgcolor
	variable bgcolor
	variable hicolor
	set bgcolor [dict get $::widgetdict desklist bg $theme]
	set fgcolor [dict get $::widgetdict desklist fg $theme]
	set hicolor [dict get $::color hl $theme]

	variable fgmenu
	variable bgmenu
	variable fgmenu2
	variable bgmenu2
	set fgmenu [dict get $::color fg $theme]
	set bgmenu [dict get $::color bg $theme]
	set fgmenu2 [dict get $::color fg2 $theme]
	set bgmenu2 [dict get $::color bg2 $theme]

	set theme_defined 1

	$desklistbar configure -background $bgcolor
	$desklistframe configure -background $bgcolor
	foreach slave [pack slaves $desklistframe] {
		if {$slave == $activeslave} {
			$slave configure -bg $hicolor -fg $fgcolor
		} else {
			$slave configure -bg $bgcolor -fg $fgcolor
		}
	}
}

proc zstatus::zwm::set_wintitle {value} {
	variable wintext
	variable winmaxlen

	set wintext $value
	set length [tcl::mathfunc::min [string length $wintext] $winmaxlen]
	variable wintitle
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -width $length
	$wintitle insert 1.0 $wintext

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

proc zstatus::zwm::clientmenu {} {
	variable clientlist
	variable fgmenu
	variable bgmenu
	variable fgmenu2
	variable bgmenu2

	if [winfo exists .clientmenu] {
		destroy .clientmenu
	}

	set menu [menu .clientmenu -font large -relief flat -activerelief solid\
			-foreground $fgmenu -background $bgmenu\
			-activebackground $bgmenu2 -activeforeground $fgmenu2\
			-disabledforeground $fgmenu]

	$menu add command -label "Clients X11" -state disabled\
			-background $bgmenu2

	foreach client $clientlist {
		$menu add command\
			-label [dict get $client name]\
			-command "zstatus::zwm::send_message activate-client=[dict get $client id]"
	}

	$menu post [winfo pointerx $menu] [winfo pointery $menu]
}

proc zstatus::zwm::set_clientlist {value} {
	variable clientlist
	set clientlist {}
	foreach w [split $value "\n"] {
		regexp {^id=([0-9]+)\|res=(.+)\|name=(.+)$} $w -> id res name
		set name [string range $name 0 227]
		set client [dict create id $id res $res name $name]
		lappend clientlist $client
	}
}

proc zstatus::zwm::set_desklist {value} {
	variable desklist
	variable desklistbar
	variable desklistframe
	variable activeslave

	destroy $desklistframe
	pack [frame $desklistframe]
	set desklist $value
	foreach name [split $value "|"] {
		if {![string length $name]} {
			continue
		}
		set active 0
		set first [string index $name 0]
		set font normal
		if {$first == "+"} {
			set num [string range $name 1 end]
			set name $num
			set font bold
			set active 1
		} elseif {$first == "!"} {
			set num [string range $name 1 end]
			set font italic
		} else {
			set num $name
		}

		set slave $desklistframe.$num
		pack [label $slave -font $font -text $name] -padx 0 -ipadx 4 -side left

		if {$active} {
			set activeslave $slave
			continue
		}

		bind $slave <1> "zstatus::zwm::send_message desktop-switch-$num"
	}

	variable theme_defined
	if {!$theme_defined} { return }

	variable hicolor
	variable bgcolor
	variable fgcolor

	$desklistbar configure -background $bgcolor
	$desklistframe configure -background $bgcolor
	foreach slave [pack slaves $desklistframe] {
		if {$slave == $activeslave} {
			$slave configure -bg $hicolor -fg $fgcolor
		} else {
			$slave configure -bg $bgcolor -fg $fgcolor
		}
	}
}

proc zstatus::zwm::set_desklayout {value} {
	variable layouts
	variable desklayout
	if [dict exists $layouts $value] {
		set desklayout [dict get $layouts $value]
	} else {
		set desklayout $value
	}
}

proc zstatus::zwm::set_deskname {value} {
	variable deskname
	set deskname $value
}

proc zstatus::zwm::setup {bar item} {
	switch $item {
	wintitle {
		dict set ::messagedict window_active\
				{action zwm::set_wintitle arg 1}
		dict set ::messagedict no_window_active\
				{action zwm::unset_wintitle arg 1}
		variable wintitle
		variable wintext
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
		set_wintitle $wintext
	}
	desklayout {
		dict set ::messagedict desklayout {action zwm::set_desklayout arg 1}
		bind $bar.desklayout <MouseWheel> {
			if {%D < 0} {
				zstatus::zwm::send_message "desktop-layout-next"
			} else {
				zstatus::zwm::send_message "desktop-layout-prev"
			}
		}
	}
	desklist {
		dict set ::messagedict desklist {action zwm::set_desklist arg 1}
		variable desklist
		variable desklistbar
		variable desklistframe
		set desklistbar [frame $bar.$item]
		set desklistframe [frame $desklistbar.frame]
		pack $desklistbar
		pack $desklistframe
		set_desklist $desklist
	}
	deskname {
		dict set ::messagedict deskname {action zwm::set_deskname arg 1}
	}}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
