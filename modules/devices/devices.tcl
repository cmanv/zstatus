package require Tk

namespace eval zstatus::devices {
	variable searchlist {{da[0-9]} {ulpt[0-9]}}
	namespace export setup update set_theme
}

proc zstatus::devices::set_theme {theme} {
	variable bgcolor
	variable fgcolor
	set bgcolor [dict get $::widgetdict devices bg $theme]
	set fgcolor [dict get $::widgetdict devices fg $theme]
	set sepcolor [dict get $::widgetdict separator bg $theme]

	variable devframe
	variable devsep
	$devframe configure -background $bgcolor
	$devsep configure -background $sepcolor

	variable devicelist
	foreach device $devicelist {
		$devframe.$device configure -bg $bgcolor -fg $fgcolor
	}
}

proc zstatus::devices::update {} {
	variable bgcolor
	variable fgcolor
	variable devicefont

	variable devframe
	variable devsep
	variable devpos
	variable devside

	variable searchlist
	variable devicelist
	set currentlist {}
	foreach pattern $searchlist {
		lappend currentlist {*}[glob -nocomplain -tails -dir "/dev" $pattern]
	}

	foreach device $currentlist {
		if {[lsearch $devicelist $device] == -1} {
			if ![string length [pack slaves $devframe]] {
				pack $devframe -after $devpos -side $devside
				pack $devsep -after $devframe -fill y \
					-side $devside
			}
			pack [label $devframe.$device -font $devicefont\
				 -text "$device" -padx 5] -side $devside
			$devframe.$device configure -fg $fgcolor\
				 -bg $bgcolor
		}
	}

	foreach device $devicelist {
		if {[lsearch $currentlist $device] == -1} {
			pack forget $devframe.$device
			if {![string length [pack slaves $devframe]]} {
				pack forget $devframe $devsep
			}
			destroy $devframe.$device
		}
	}
	set devicelist $currentlist
}

proc zstatus::devices::setup { base position side } {
	variable devframe
	variable devsep
	variable devpos
	variable devside

	set devframe $base.devices
	set devsep $base.devivessep
	set devpos $base.$position
	set devside $side

	frame $devframe
	frame $devsep -width 1

	variable devicefont 
	set devicefont [dict get $::widgetdict devices font]

	variable devicelist
	set devicelist {}

	variable searchlist
	if [dict exists $::widgetdict devices searchlist] {
		set value [dict get $::widgetdict devices searchlist] 
		regsub -all {\"} $value {} value
		regsub -all {,} $value { } value
		regsub -all {[ ]+} $value { } value
		set searchlist [split $value]
	}
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
