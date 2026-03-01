package require Tk
package require fileutil
package require mime

namespace eval zstatus::mail {
	dict set ::moduledict mail { themefunc mail::set_theme }

	variable activepopup 0
	namespace export setup update set_theme
}

proc zstatus::mail::set_theme { theme } {
	variable bgcolor
	variable fgcolor
	variable sepcolor
	set bgcolor [dict get $::widgetdict mail bg $theme]
	set fgcolor [dict get $::widgetdict mail fg $theme]
	set sepcolor [dict get $::widgetdict separator bg $theme]

	variable mailframe
	variable mailsep
	$mailframe configure -background $bgcolor
	$mailsep configure -background $sepcolor
	foreach index [dict keys $::mailboxes] {
		$mailframe.$index configure\
			-bg [dict get $::mailboxes $index bg $theme]\
			-fg [dict get $::mailboxes $index fg $theme]
	}
}

proc zstatus::mail::convert_date { rfc822 } {
	set ctime [clock scan $rfc822]
	set timezone [dict get $::config timezone]
	set locale [dict get $::config locale]
	set date [clock format $ctime -format {%a %d %b %Y %T %Z} \
			-timezone $timezone -locale $locale]
	return $date
}

proc zstatus::mail::convert_header { header } {
	set tokens [regexp -linestop -all -inline\
			 {(.*)=\?([\w\-]+)\?(.)\?(.*?)\?\=(.*)} $header]

	if { $tokens == {} } {
		return $header
	}

	set result ""
	foreach { _ head charset enctype value tail } $tokens {
		if { [string is space $head] } {
			if { [string length $result] } {
				set head " "
			} else {
				set head ""
			}
		}
		if { [string is space $tail] } {
			set tail ""
		}
		set charset [string tolower $charset]
		if { [string match iso-* $charset] } {
			set charset [string replace $charset 0 3 iso]
		} elseif { [string match windows-* $charset] } {
			set charset [string replace $charset 0 7 cp]
		}
		set enctype [string tolower $enctype]
		if { $enctype == "b" } {
			set value [::base64::decode $value]
		} elseif { $enctype == "q" } {
			set value [::mime::qp_decode $value 1]
		}
		set value [encoding convertfrom $charset $value]
		set result "${result}${head}${value}${tail}"
	}

	return $result
}

# Popup after button event on mail icon
proc zstatus::mail::new { index } {
	variable activepopup
	variable barwidget
	variable mail
	variable mailfont
	variable mailframe
	variable bgcolor
	variable fgcolor
	variable sepcolor

	if {$activepopup} {
		destroy .mailpopup
	} else {
		set activepopup 1
	}

	set mailpopup [toplevel .mailpopup -background $bgcolor -class Newmail]

	set xpos [winfo rootx $mailframe]
	set ypos [expr [winfo rooty $barwidget] + [winfo height $barwidget] + 1]

	wm attributes $mailpopup -type dialog
	wm overrideredirect $mailpopup 1
	wm geometry $mailpopup +$xpos+$ypos

	bind $mailpopup <Map> { zstatus::map_window .mailpopup }

	set mailboxname [dict get $::mailboxes $index name]
	set mailboxpath [dict get $::mailboxes $index path]
	pack [frame $mailpopup.$index -background $bgcolor]\
		-expand 1 -fill x -side top
	pack [label $mailpopup.$index.label -font bold -bg $bgcolor\
		-fg $fgcolor -text "-- $mailboxname --"] \
		-expand 1 -side left
	pack [frame $mailpopup.headersep -background $sepcolor\
		-height 1] -fill x -side top

	set count 0
	foreach file [lsort -decreasing [glob -nocomplain -dir "$mailboxpath/new" *]] {
		if [catch {set mesg [fileutil::cat $file]} error] {
			puts "[info level 0]: $error"
			continue
		}
		set tokens [mime::initialize -string $mesg]
		set date [convert_date [lindex [mime::getheader $tokens Date] 0]]
		set from [convert_header [lindex [mime::getheader $tokens From] 0]]
		set subject [convert_header [lindex [mime::getheader $tokens Subject] 0]]

		pack [frame $mailpopup.date$count -background $bgcolor]\
			-expand 1 -fill x
		pack [label $mailpopup.date$count.label -text $date\
			-font $mailfont -bg $bgcolor\
			-fg $fgcolor] -side left -padx 5
		pack [frame $mailpopup.from$count -background $bgcolor]\
			-expand 1 -fill x
		pack [label $mailpopup.from$count.label -text $from\
			-font $mailfont -bg $bgcolor\
			-fg $fgcolor] -side left -padx 5
		pack [frame $mailpopup.subject$count -background $bgcolor]\
			-expand 1 -fill x

		set textlen [string length $subject]
		set width [string length [lindex [split $subject "\n"] 0]]
		set height [tcl::mathfunc::ceil [expr ($textlen / ($width + 0.0))]]

		set tsubject [text $mailpopup.subject$count.text -font $mailfont\
			-wrap word -borderwidth 0 -highlightthickness 0\
			-height $height -width $width -fg $fgcolor\
			-bg $bgcolor]

		pack $tsubject -side left -padx 5
		$tsubject tag configure emoji -font emoji
		$tsubject insert 1.0 $subject
		foreach i [$tsubject search -all -regexp {[\u2000-\u28ff\U1f000-\U1faff]} 1.0 end] {
			$tsubject tag add emoji $i
		}

		pack [frame $mailpopup.msgsep$count -background $sepcolor\
			-height 1] -side top -fill x
		incr count
	}

}

proc zstatus::mail::update {} {
	variable mailframe
	variable mailsep
	variable mailpos
	variable mailside
	variable mailicon

	foreach index [dict keys $::mailboxes] {
		set newmail [dict get $::mailboxes $index newmail]
		set path [dict get $::mailboxes $index path]
		set inbox [llength [glob -nocomplain -dir "$path/new" *]]
		if {$inbox && $newmail != $inbox} {
			dict set ::mailboxes $index newmail $inbox
			$mailframe.$index configure -text "$mailicon ($inbox) "
			if ![dict get $::mailboxes $index visible] {
				if {![string length [pack slaves $mailframe]]} {
					pack $mailframe -after $mailpos \
						-side $mailside
					pack $mailsep -after $mailframe \
						-fill y -padx 5 -side $mailside
				}
				pack $mailframe.$index -side left
				dict set ::mailboxes $index visible 1
			}
		} else {
			if {!$inbox && [dict get $::mailboxes $index visible]} {
				pack forget $mailframe.$index
				if {![string length [pack slaves $mailframe]]} {
					pack forget $mailframe $mailsep
				}
				dict set ::mailboxes $index newmail 0
				dict set ::mailboxes $index visible 0
			}
		}
	}
}

proc zstatus::mail::setup { bar position side } {
	variable barwidget
	variable mailframe
	variable mailsep
	variable mailpos
	variable mailside

	set barwidget $bar
	set mailframe $bar.mailframe
	set mailsep $bar.mailsep
	set mailpos $bar.$position
	set mailside $side

	frame $mailframe
	frame $mailsep -width 1

	variable mailfont
	variable mailicon
	set mailfont [dict get $::widgetdict mail font]
	set mailicon $::unicode(mail)

	set mailclient ""
	if [dict exists $::widgetdict mail exec] {
		set mailclient [dict get $::widgetdict mail exec]
	}
	foreach index [dict keys $::mailboxes] {
		dict set ::mailboxes $index visible 0
		dict set ::mailboxes $index newmail 0

		label $mailframe.$index -font normal -text ""
		bind $mailframe.$index <Enter> "zstatus::mail::new $index"
		bind $mailframe.$index <Leave> {
			destroy .mailpopup
			set zstatus::mail::activepopup 0
		}
		if [string length $mailclient] {
			bind $mailframe.$index <1> "exec $mailclient >/dev/null 2>@1 &"
		}
	}
}
package provide @PROJECT_NAME@ @PROJECT_VERSION@
