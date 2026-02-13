package require Tk
package require zstatus::music::mpd

namespace eval zstatus::music {
	variable socket_valid 0
	variable tooltip_active 0
	array set mpdstates { 2 play 3 pause }

	namespace export command setup update set_theme show_tooltip hide_tooltip
}

proc zstatus::music::set_theme { theme } {
	variable socket_valid
	if {!$socket_valid} { return }

	variable bgcolor
	variable fgcolor
	variable musicbg
	variable musicfg

	set musicfg [dict get $::widgetdict music fg $theme]
	set musicbg [dict get $::widgetdict music bg $theme]
	set bgcolor [dict get $::color bg $theme]
	set fgcolor [dict get $::color fg $theme]
	set sepcolor [dict get $::widgetdict separator bg $theme]

	variable musicframe
	variable musicsep
	$musicframe configure -bg $musicbg -fg $musicfg
	$musicsep configure -background $sepcolor
}

proc zstatus::music::command {action} {
	if {![catch {exec mpc $action}]} {
		zstatus::music::update
	}
}

proc zstatus::music::update {} {
	variable socket_valid
	if {!$socket_valid} { return }

	variable musicframe
	variable musicsep
	variable musicpos
	variable musicside
	variable music_active
	variable tooltip_active
	variable mpdstates

	set state [mpd::state]
	if {$state > 1} {
		$musicframe configure -text $::unicode($mpdstates($state))
		if {!$music_active} {
			pack $musicframe -after $musicpos -side $musicside
			pack $musicsep -after $musicframe -fill y -padx 5 -side $musicside
			set music_active 1
		}
	} else {
		if {$music_active} {
			pack forget $musicframe $musicsep
			set music_active 0
		}
	}
	if { $music_active && $tooltip_active } {
		update_tooltip
	}
}

proc zstatus::music::setup { bar position side } {
	variable mpdsocket
	if [dict exists $::widgetdict music socket] {
		set mpdsocket [dict get $::widgetdict music socket]
	} elseif [info exists ::env(MPD_HOST)] {
		set mpdsocket $::env(MPD_HOST)
	}
	variable musicfont
	set musicfont [dict get $::widgetdict music font]

	variable barwidget
	variable musicframe
	variable musicsep
	variable musicpos
	variable musicside

	set barwidget $bar
	set musicframe $bar.music
	set musicsep $bar.musicsep
	set musicpos $bar.$position
	set musicside $side
	label $musicframe -font $musicfont
	frame $musicsep -width 1

	dict set ::messagedict music music::command
	bind $musicframe <Enter> { zstatus::music::show_tooltip }
	bind $musicframe <Leave> { zstatus::music::hide_tooltip }
	bind $musicframe <1> {
		if {![catch {exec mpc toggle}]} { zstatus::music::update }
	}
	bind $musicframe <2> {
		exec xterm +sb -class ncmpcpp -e ncmpcpp &
	}
	bind $musicframe <3> {
		if {![catch {exec mpc stop}]} { zstatus::music::update }
	}
	bind $musicframe <MouseWheel> {
		if {%D < 0} {
			if {![catch {exec mpc next}]} { zstatus::music::update_tooltip }
		} else {
			if {![catch {exec mpc prev}]} { zstatus::music::update_tooltip }
		}
	}

	variable music_active 0
	variable socket_valid 0
	if [catch {mpd::connect $mpdsocket} error] {
		puts stderr $error
	} else {
		set socket_valid 1
	}
}

# Show info on current track
proc zstatus::music::show_tooltip {} {
	variable tooltip_active
	variable mpdtext
	variable musicfont
	variable bgcolor
	variable barwidget
	variable musicframe

	set tooltip_active 1
	set tooltip [toplevel .musictooltip -highlightthickness 0\
			-background $bgcolor]

	set xpos [winfo rootx $musicframe]
	set ypos [expr [winfo rooty $barwidget] + [winfo height $barwidget] + 1]

	wm title $tooltip "Now Playing"
	wm attributes $tooltip -type dialog
	wm overrideredirect $tooltip 1
	wm geometry $tooltip +$xpos+$ypos

	set mpdtext [text $tooltip.text -font $musicfont\
			-bd 0 -highlightthickness 0 -height 3]
	pack $mpdtext -side left -padx 5 -pady 3

	bind $tooltip <Map> { zstatus::map_window .musictooltip }
	update_tooltip
}

proc zstatus::music::hide_tooltip {} {
	variable tooltip_active

	set tooltip_active 0
	destroy .musictooltip
}

# Update info on current track
proc zstatus::music::update_tooltip { } {
	variable music
	variable mpdtext
	variable bgcolor
	variable fgcolor

	set info [mpd::currenttitle]
	set title "[lindex $info 0] - [lindex $info 1]\n"
	append title "[lindex $info 2]  "
	append title "([lindex $info 3] de [lindex $info 4])\n"
	append title "[lindex $info 5]  (Durée [lindex $info 6])"

	set width 0
	foreach line [split $title \n] {
		set width [tcl::mathfunc::max [string length $line] $width]
	}
	$mpdtext delete 1.0 end
	$mpdtext insert 1.0 $title
	$mpdtext configure -width $width -fg $fgcolor -bg $bgcolor
}

package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
