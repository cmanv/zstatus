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
	variable desklist "+?"
	variable desklayout "?"
	variable active_title ""
	variable active_desk "?"
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
	variable active_desk
	variable active_title
	variable textmaxlen

	regexp {^id=([0-9]+)\|desk=([0-9]+)\|name=(.*)$} $value -> id desk name

	set active_client $id
	set active_desk $desk
	set active_title $name

	set length [tcl::mathfunc::min [string length $name] $textmaxlen]
	incr length
	variable wintitle
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -width $length
	$wintitle insert 1.0 $active_title

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
	variable active_title
	variable wintitle

	set active_client 0
	set active_title ""
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -state disabled
}

proc zstatus::zwm::client_menu {} {
	variable labeldict
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

	variable locale
	$menu add command -state disabled -background $bgmenu2\
		-label [dict get $labeldict clientmenu $locale]

	variable active_client
	variable active_desk
	foreach client $clientlist {
		set mark "_"
		if {$active_client == [dict get $client id]} {
			set mark "*"
		} elseif {$active_desk == [dict get $client desk]} {
			set mark "+"
		}
		set entry "\[[dict get $client desk]\] $mark [dict get $client name]"
		set id [dict get $client id]
		$menu add command -label $entry\
			-command "zstatus::zwm::send_message activate-client=$id"
	}
	$menu post {*}[winfo pointerxy .] 1
}

proc zstatus::zwm::set_clientlist {value} {
	variable clientlist
	set clientlist {}
	foreach w [split $value "\n"] {
		regexp {^id=([0-9]+)\|res=(.+)\|desk=([0-9]+)\|name=(.*)$} $w\
			-> id res desk name
		if {$desk == 0} { set desk s}
		regsub -all {[\u2700-\u27bf\U1f000-\U1faff]+} $name {*} name
		set client [dict create id $id res $res desk $desk name $name]
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
	foreach d [split $value "\n"] {
		regexp {^desk=([0-9]+)\|state=([a-z]+)$} $d -> desk state
		set name $desk
		set font normal
		if {$state == "active"} {
			set font bold
		} elseif {$state == "urgent"} {
			set name "$desk!"
		}

		set slave $desklistframe.$desk
		pack [label $slave -font $font -text $name] -padx 0 -ipadx 4 -side left

		if {$state == "active"} {
			set activeslave $slave
			continue
		}

		bind $slave <1> "zstatus::zwm::send_message desktop-switch-$desk"
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
		dict set ::messagedict active_client\
				{action zwm::set_wintitle arg 1}
		dict set ::messagedict no_active_client\
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
