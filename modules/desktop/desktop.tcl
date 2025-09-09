#!/usr/bin/env wish9.0
namespace eval zstatus::desktop {
	array set modes {Monocle M VTiled V HTiled H Stacked S}
	namespace export set_wintitle unset_wintitle set_desklit set_deskname\
			set_deskmode
}

proc zstatus::desktop::set_wintitle {value} {
	set maxlength [dict get $::widgetdict wintitle maxlength]
	set length [tcl::mathfunc::min [string length $value] $maxlength]
	variable wintitle
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -width $length
	$wintitle insert 1.0 $value
	foreach i [$wintitle search -all \
		-regexp {[\u2000-\u28ff\U1f000-\U1faff]} 1.0 end] {
		$wintitle tag add emoji $i
	}
	$wintitle configure -state disabled
}

proc zstatus::desktop::unset_wintitle {value} {
	variable wintitle
	$wintitle configure -state normal
	$wintitle delete 1.0 end
	$wintitle configure -state disabled
}

proc zstatus::desktop::set_desklist {value} {
	variable desklist
	set desklist $value
}

proc zstatus::desktop::set_deskmode {value} {
	variable modes
	variable deskmode
	if [info exists modes($value)] {
		set deskmode " $modes($value)"
	} else {
		set deskmode " $value"
	}
}

proc zstatus::desktop::set_deskname {value} {
	variable deskname
	set deskname $value
}

proc zstatus::desktop::setup {bar item} {
	switch $item {
	wintitle {
		dict set ::messagedict window_active\
				{action desktop::set_wintitle arg 1}
		dict set ::messagedict no_window_active\
				{action desktop::unset_wintitle arg 1}
		variable wintitle
		set wintitle [text $bar.$item\
			-font [dict get $::widgetdict wintitle font]\
			-height 1 -borderwidth 0\
			-highlightthickness 0 -wrap word]
		$bar.$item tag configure emoji -font emoji
		$bar.$item configure -state disabled
	}
	deskmode {
		dict set ::messagedict desktop_mode {action desktop::set_deskmode arg 1}
		bind $bar.deskmode <MouseWheel> {
			if {%D < 0} {
				zstatus::send_message "desktop-mode-next"
			} else {
				zstatus::send_message "desktop-mode-prev"
			}
		}
	}
	desklist {
		dict set ::messagedict desktop_list {action desktop::set_desklist arg 1}
		bind $bar.desklist <MouseWheel> {
			if {%D < 0} {
				zstatus::send_message "desktop-switch-next"
			} else {
				zstatus::send_message "desktop-switch-prev"
			}
		}
	}
	deskname {
		dict set ::messagedict desktop_name {action desktop::set_deskname arg 1}
	}}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
