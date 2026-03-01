package require fileutil

namespace eval zstatus::config {
	set std_map {
		arrow-up	\u2191
		arrow-down	\u2193
		arrow-up-down	\u21c5
		pause		\u23f8
		menu		\u2630
		question-mark	\u2753
		layout		\u29c9
		empty		\u29b0
		play		\u2bc8
		window		\U1f5d6
		windows		\U1f5d7
		mail 		\U1f5be
		cpu		\U1d402
		memory		\U1d40c
		bar-chart	\U1f4ca
		music		\U1f39d
		volume		\U1f50a
	}

	set pua_map {
		cloud-windy \ueba1
		overcast \ueba5
		drizzle \uec68
		fog \ued50
		hail \ueded
		haze \uee00
		heavy-showers \uee15
		mist \uef5d
		night-clear \uef6f
		night-cloudy \uef71
		night-few-clouds \uef74
		rain \uf056
		showers \uf122
		snowflake \uf513
		snow \uf15e
		day-cloudy \uf1bb
		day-few-clouds \uf1be
		day-clear \uf1bf
		thunderstorm \uf209
		tornado \uf21c
		windy \uf2ca
	}

	array set ::unicode [list {*}$std_map {*}$pua_map]

	set color [dict create\
		fg { light black dark LightGray }\
		fg2 { light black dark seashell }\
		bg { light seashell dark DarkSlateGray }\
		bg2 { light SlateGray2 dark SteelBlue4 }\
		line { light DeepSkyBlue dark SeaGreen }]

	set widgetdict [dict create\
		datetime {
			type string
			format {%e %b %H:%M}
			proc set_datetime
			source zstatus::datetime
		} devices {
			type transient
			module devices
			proc devices::update
			font bold\
		} loadavg {\
			type string
			module system
			proc system::set_loadavg
			source zstatus::system::loadavg
		} mail {
			type transient
			module mail
			font bold
			proc mail::update
		} memused {
			type string
			module system
			proc system::set_memused
			source zstatus::system::memused
		} metar {
			type string
			module metar
			proc metar::update
			source zstatus::metar::report(statusbar)
			delay 10
			font pua1
		} mixer {
			type string
			module system
			source zstatus::system::mixer
		} music {
			type transient
			module music
			proc music::update
		} netstat {
			type string
			module system
			interface em0
			proc system::update_netstat
			source zstatus::system::neticon
		} osversion {
			type string
			source zstatus::osversion
		} separator {
			type separator
			bg { light sienna dark gray }
		} wintitle {
			type text
			module zwm
			expand 0
			maxlength 120
		} desklist {
			type frame
			module zwm
			font mono
		} clientmenu {
			type menubutton
			module zwm
			path x11clients
			post zstatus::zwm::gen_client_menu
			source zstatus::zwm::clienttitle
		} layoutmenu {
			type menubutton
			module zwm
			path layouts
			post zstatus::zwm::gen_layout_menu
			source zstatus::zwm::layouttitle
		} deskname {
			type string
			module zwm
			source zstatus::zwm::deskname
		} launchermenu {
			type menubutton
			path launchers
			post zstatus::gen_launcher_menu
			source zstatus::launchertitle
		}]

	if [info exists ::env(XDG_CONFIG_HOME)] {
		set config_prefix $::env(XDG_CONFIG_HOME)
	} else {
		set config_prefix $::env(HOME)/.config
	}

	variable defaultfile "$config_prefix/zstatus/config"
	variable menudef "$config_prefix/zstatus/menudef.json"

	if [info exists ::env(XDG_CACHE_HOME)] {
		set cache_prefix $::env(XDG_CACHE_HOME)
	} else {
		set cache_prefix $::env(HOME)/.cache
	}

	set config [dict create\
		timezone 	[exec date +%Z]\
		delay		2000\
		fontname	"Dejavu Sans"\
		fontsize	11\
		menudef		$menudef\
		position	top\
		font_pua	remixicon\
		cache_prefix	$cache_prefix]

	if [info exists ::env(LANG)] {
		set lang $::env(LANG)
	} else {
		set lang C
	}

	set locales {C fr}
	set index [lsearch $locales [lindex [split $lang "_"] 0]]
	if {$index < 0} {
		dict set config locale C
	} else {
		dict set config locale [lindex $locales $index]
	}

	dict set config leftside {layoutmenu separator desklist separator\
					deskname separator wintitle}
	dict set config rightside datetime

	namespace export read get unicode
}

proc zstatus::config::get {key configfile} {
	variable defaultfile
	variable config

	if {$configfile == "default"} {
		set configfile $defaultfile
	}

	set value ""
	if [dict exists $config $key] {
		set value [dict get $config $key]
	}

	if [file exists $configfile] {
		set context ""
		set lines [fileutil::cat $configfile]
		foreach line $lines {
			if ![string length $line] { continue }
			if [regexp {^#} $line] { continue }
			if [regexp {^\[([a-z_]+)\]} $line -> context] {
				if {$context != "main"} {
					set context ""
				}
				continue
			}
			if ![string length $context] { continue }
			if [regexp "^$key=(.+)" $line -> value] {
				break
			}
		}
	}

	return $value
}

proc zstatus::config::read {configfile} {
	variable defaultfile
	variable color
	variable config
	variable widgetdict

	# List of valid contexts in config file
	set contexts { main clientmenu color datetime layoutmenu desklist deskname\
		devices launchermenu layoutmenu loadavg mail maildir memused metar\
		mixer music netstat osversion separator wintitle}

	# Cant change these from config file
	set immutables {type source proc setup}

	if {$configfile == {default}} {
		set configfile $defaultfile
	}

	set ::color $color
	set ::config $config
	set ::widgetdict $widgetdict
	set ::mailboxes {}
	if [file exists $configfile] {
		set index 0
		set context ""
		set lines [split [fileutil::cat $configfile] "\n"]
		foreach line $lines {
			if ![string length $line] { continue }
			if [regexp {^#} $line] { continue }
			if [regexp {^\[([a-z_]+)\]} $line -> context] {
				if {[lsearch $contexts $context] < 0} {
					set context ""
				}
				if {$context == "maildir"} {
					incr index
				}
				continue
			}
			if ![string length $context] { continue }
			if [regexp {^([0-9a-z_]+)\.([a-z_]+)=(.+)} $line -> key1 key2 value] {
				if {$context == "main"} {
					dict set ::config $key1 $key2 $value
				} elseif {$context == "color"} {
					dict set ::color $key1 $key2 $value
				} elseif {$context == "maildir"} {
					dict set ::mailboxes $index $key1 $key2 $value
				} else {
					dict set ::widgetdict $context $key1 $key2 $value
				}
				continue
			}
			if [regexp {^([a-z_]+)=(.+)} $line -> key value] {
				if {[lsearch $immutables $key] >= 0} {
					continue
				}
				if {$context == "main"} {
					dict set ::config $key $value
				} elseif {$context == "color"} {
					dict set ::color $key $value
				} elseif {$context == "maildir"} {
					dict set ::mailboxes $index $key $value
				} else {
					dict set ::widgetdict $context $key $value
				}
			}
		}
	}

	# Fill in default values
	foreach key [dict keys $::widgetdict] {
		if {![dict exists $::widgetdict $key font]} {
			dict set ::widgetdict $key font normal
		}
		if { ![dict exists $::widgetdict $key fg light] } {
			dict set ::widgetdict $key fg light\
				[dict get $::color fg light]
		}
		if { ![dict exists $::widgetdict $key fg dark] } {
			dict set ::widgetdict $key fg dark\
				[dict get $::color fg dark]
		}
		if { ![dict exists $::widgetdict $key bg light] } {
			dict set ::widgetdict $key bg light\
				[dict get $::color bg light]
		}
		if { ![dict exists $::widgetdict $key bg dark] } {
			dict set ::widgetdict $key bg dark\
				[dict get $::color bg dark]
		}
	}
	foreach index [dict keys $::mailboxes] {
		if ![dict exists $::mailboxes $index fg light] {
			dict set ::mailboxes $index fg light [dict get $color fg light]
		}
		if ![dict exists $::mailboxes $index fg dark] {
			dict set ::mailboxes $index fg dark [dict get $color fg dark]
		}
		if ![dict exists $::mailboxes $index bg light] {
			dict set ::mailboxes $index bg light [dict get $color bg light]
		}
		if ![dict exists $::mailboxes $index bg dark] {
			dict set ::mailboxes $index bg dark [dict get $color bg dark]
		}
		if {![dict exists $::mailboxes $index name]||\
			 ![dict exists $::mailboxes $index path]} {
			dict unset ::mailboxes $index
		}
	}
}
package provide @PROJECT_NAME@ @PROJECT_VERSION@
