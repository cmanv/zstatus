namespace eval zstatus::zwm {
	variable layouts [dict create\
		Monocle	$::unicode(rectangle)\
		VTiled	$::unicode(layout-column)\
		HTiled	$::unicode(layout-row)\
		Stacked	$::unicode(file-copy)]

	variable locale [dict get $::config locale]

	dict set ::messagedict clientlist {action zwm::set_clientlist arg 1}
	dict set ::messagedict client_menu {action zwm::client_menu arg 0}
	dict set labeldict clientmenu { C "X11 Clients" fr "Clients X11"}

	variable screen [lindex [split [winfo screen .] "."] 1]
	variable zwmsocket "[dict get $::config cache_prefix]/zwm/socket"

	variable clientlist {}
	variable desklist {}
	variable desklayout "?"
	variable active_client [dict create window 0 desk ? name "" ]
	variable textmaxlen [dict get $::widgetdict wintitle maxlength]
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
	set hicolor [dict get $::color bg2 $theme]

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
	variable active_client
	variable textmaxlen

	set active_client $value
	set name [dict get $active_client name]
	set length [tcl::mathfunc::min [string length $name] $textmaxlen]
	incr length
	variable wintitle
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -width $length
	$wintitle insert 1.0 $name

	variable emojis
	if {$emojis} {
		foreach e [$wintitle search -all \
			-regexp {[\u2000-\u28ff\U1f000-\U1faff]} 1.0 end] {
			$wintitle tag add emoji $e
		}
	}
	$wintitle configure -state disabled
}

proc zstatus::zwm::unset_wintitle {} {
	variable active_client
	variable wintitle

	dict set active_client window 0
	dict set active_client name ""
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -state disabled
}

proc zstatus::zwm::client_menu {} {
	set menu [gen_client_menu .x11clients]
	$menu post {*}[winfo pointerxy .] 1
}

proc zstatus::zwm::gen_client_menu { path } {
	variable labeldict
	variable clientlist
	variable fgmenu
	variable bgmenu
	variable fgmenu2
	variable bgmenu2

	if [winfo exists $path] {
		destroy $path
	}

	set menu [menu $path -font large\
			-relief flat -activerelief solid\
			-foreground $fgmenu -background $bgmenu\
			-activeforeground $fgmenu2 -activebackground $bgmenu2\
			-disabledforeground $fgmenu]

	variable locale
	$menu add command -state disabled -background $bgmenu2\
		-label [dict get $labeldict clientmenu $locale]

	variable active_client
	set active_window [dict get $active_client window]
	set active_desknum [dict get $active_client desknum]
	foreach client $clientlist {
		set mark "_"
		set window [dict get $client window]
		set desknum [dict get $client desknum]
		if {$active_window == $window} {
			set mark "*"
		} elseif {$active_desknum == $desknum} {
			set mark "+"
		}
		set entry "\[$desknum\] $mark [dict get $client name]"
		$menu add command -label $entry\
			-command "zstatus::zwm::send_message activate-client=$window"
	}
	return $menu
}

proc zstatus::zwm::set_clientlist {values} {
	variable clientlist
	set clientlist $values
	foreach client $clientlist {
		if {[dict get $client desknum] == 0} {
			dict set client desknum s
		}
		set name [dict get $client name]
		regsub -all {[\u2700-\u27bf\U1f000-\U1faff]+} $name {*} name
		dict set client name $name
	}
}

proc zstatus::zwm::set_desklist {values} {
	variable desklist
	variable desklistbar
	variable desklistframe
	variable activeslave

	destroy $desklistframe
	pack [frame $desklistframe]
	set desklist $values
	foreach desk $desklist {
		set desknum [dict get $desk desknum]
		set state [dict get $desk state]

		set label $desknum
		set font normal
		if {$state == "active"} {
			set font bold
		} elseif {$state == "urgent"} {
			set label "$desknum!"
		}

		set slave $desklistframe.$desk
		pack [label $slave -font $font -text $label] -padx 0 -ipadx 4 -side left

		if {$state == "active"} {
			set activeslave $slave
			continue
		}

		bind $slave <1> "zstatus::zwm::send_message desktop-switch-$desknum"
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
		dict set ::messagedict active_window\
				{action zwm::set_wintitle arg 1}
		dict set ::messagedict no_active_window\
				{action zwm::unset_wintitle arg 0}
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
	}
	deskname {
		dict set ::messagedict deskname {action zwm::set_deskname arg 1}
	}}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
