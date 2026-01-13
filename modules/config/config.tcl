package require fileutil

namespace eval zstatus::config {
	set color [dict create\
		fg { light black dark LightGray }\
		bg { light gray90 dark gray20 }\
		hl { light SlateGray2 dark SteelBlue4 }\
		line { light DeepSkyBlue dark SeaGreen }]

	set widgetdict [dict create\
		datetime {
			type string
			format {%d %b %H:%M}
			proc set_datetime
			source zstatus::datetime
		} devices {
			type transient
			module devices
			proc devices::update
			settheme devices::set_theme
			font bold\
		} loadavg {\
			type string
			module system
			proc system::set_loadavg
			source zstatus::system::loadavg
		} mail {
			type transient
			module mail
			proc mail::update
			settheme mail::set_theme
		} memused {
			type string
			module system
			proc system::set_memused
			source zstatus::system::memused
			settheme system::set_theme
		} metar {
			type string module metar
			source zstatus::metar::report(statusbar)
			settheme metar::set_theme
			delay 10
			font remix1
		} mixer {
			type string
			module system
			source zstatus::system::mixer
		} music {
			type transient
			module music
			proc music::update
			settheme music::set_theme
		} netstat {
			type string
			module system
			interface em0
			proc system::update_netstat
			source zstatus::system::interface
			settheme system::set_theme
		} osversion {
			type string
			source zstatus::osversion
		} separator {
			type separator
			bg { light black dark gray }
		} wintitle {
			type text
			module zwm
			expand 0
			maxlength 120
		} wslist {
			type widget
			module zwm
			settheme zwm::set_theme
			font mono
		} wsmode {
			type string
			module zwm
			source zstatus::zwm::wsmode
		} wsname {
			type string
			module zwm
			source zstatus::zwm::wsname
		}]

	if [info exists ::env(XDG_CONFIG_HOME)] {
		set config_prefix $::env(XDG_CONFIG_HOME)
	} else {
		set config_prefix $::env(HOME)/.config
	}

	variable defaultfile "$config_prefix/zstatus/config"

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
		position	top\
		bg		[dict get $color bg]\
		cache_prefix	"$cache_prefix"]

	if [info exists ::env(LANG)] {
		dict set config lang $::env(LANG)
	} else {
		dict set config lang C
	}

	dict set config leftside {deskmode separator desklist separator\
					deskname separator wintitle}
	dict set config rightside datetime

	namespace export read get
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
	set contexts { main datetime devices loadavg mail maildir\
		memused metar mixer music netstat osversion separator\
		wintitle wslist wsmode wsname}

	# Cant change these from config file
	set immutables {type source proc setup settheme}

	if {$configfile == {default}} {
		set configfile $defaultfile
	}

	set ::color $color
	set ::config $config
	set ::widgetdict $widgetdict

	set mailboxes {}
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
			if [regexp {^([a-z_]+)\.([a-z_]+)=(.+)} $line -> key1 key2 value] {
				if {$context == "main"} {
					dict set ::config $key1 $key2 $value
				} elseif {$context == "maildir"} {
					dict set mailboxes $index $key1 $key2 $value
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
				} elseif {$context == "maildir"} {
					dict set mailboxes $index $key $value
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
				[dict get $color fg light]
		}
		if { ![dict exists $::widgetdict $key fg dark] } {
			dict set ::widgetdict $key fg dark\
				[dict get $color fg dark]
		}
		if { ![dict exists $::widgetdict $key bg light] } {
			dict set ::widgetdict $key bg light\
				[dict get $color bg light]
		}
		if { ![dict exists $::widgetdict $key bg dark] } {
			dict set ::widgetdict $key bg dark\
				[dict get $color bg dark]
		}
	}
	foreach index [dict keys $mailboxes] {
		if ![dict exists $mailboxes $index fg light] {
			dict set mailboxes $index fg light [dict get $color fg light]
		}
		if ![dict exists $mailboxes $index fg dark] {
			dict set mailboxes $index fg dark [dict get $color fg dark]
		}
		if ![dict exists $mailboxes $index bg light] {
			dict set mailboxes $index bg light [dict get $color bg light]
		}
		if ![dict exists $mailboxes $index bg dark] {
			dict set mailboxes $index bg dark [dict get $color bg dark]
		}
		if {![dict exists $mailboxes $index name]||\
			 ![dict exists $mailboxes $index path]} {
			dict unset mailboxes $index
		}
	}
	dict set ::config mailboxes $mailboxes
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
