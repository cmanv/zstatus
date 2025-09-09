#!/usr/bin/env tclsh9.0
package require fileutil

namespace eval zstatus::config {
	set config [dict create]
	if [info exists ::env(XDG_CONFIG_HOME)] {
		set config_prefix $::env(XDG_CONFIG_HOME)
	} else {
		set config_prefix $::env(HOME)/.config
	}

	if [info exists ::env(XDG_CACHE_HOME)] {
		set cache_prefix $::env(XDG_CACHE_HOME)
	} else {
		set cache_prefix $::env(HOME)/.cache
	}
	if [info exists ::env(LANG)] {
		dict set config lang $::env(LANG)
	} else {
		dict set config lang C
	}

	variable defaultfile "$config_prefix/zstatus/config"

	dict set config timezone 	[exec date +%Z]
	dict set config delay		2000
	dict set config	fontname	NotoSans
	dict set config	fontsize	11
	dict set config	emojifontname	NotoSansEmoji
	dict set config	emojifontsize	11
	dict set config	barsocket	"$cache_prefix/zstatus/socket"
	dict set config	zwmsocket 	"$cache_prefix/zwm/socket"

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
			if [regexp "^$key=(.+)" $line -> $value] {
				break
			}
		}
	}

	return $value
}

proc zstatus::config::read {configfile} {
	variable defaultfile
	variable config

	# List of valid contexts in config file
	set contexts { main arcsize datetime desklist deskmode deskname\
		devices loadavg mail maildir memused metar mixer music\
		netin netout sep separator statusbar wintitle}

	# Cant change these from config file
	set immutables {type source proc setup settheme}

	if {$configfile == {default}} {
		set configfile $defaultfile
	}

	dict set config leftside {deskmode separator desklist separator\
					deskname separator wintitle}
	dict set config rightside datetime

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
			if [regexp {^([a-z_]+)=(.+)} $line -> key value] {
				if {[lsearch $immutables $key] >= 0} {
					continue
				}
				if {$context == "main"} {
					dict set config $key $value
				} elseif {$context == "maildir"} {
					dict set mailboxes $index $key $value
				} else {
					dict set ::widgetdict $context $key $value
				}
			}
		}
	}

	# Validate mailboxes
	foreach index [dict keys $mailboxes] {
		if ![dict exists $mailboxes $index light] {
			dict set mailboxes $index light black
		}
		if ![dict exists $mailboxes $index dark] {
			dict set mailboxes $index dark LightGray
		}
		if {![dict exists $mailboxes $index name]||\
			 ![dict exists $mailboxes $index path]} {
			dict unset mailboxes $index
		}
	}
	dict set config mailboxes $mailboxes

	return $config
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
