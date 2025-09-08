#!/usr/bin/env tclsh9.0
package require fileutil

namespace eval zstatus::config {
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
		set config(lang) $::env(LANG)
	} else {
		set config(lang) C
	}

	variable defaultfile "$config_prefix/zstatus/config"

	array set config [ list \
		timezone	[exec date +%Z]\
		delay		2000\
		fontname	NotoSans\
		fontsize	11\
		emojifontname	NotoSansEmoji\
		emojifontsize	11\
		barsocket	"$cache_prefix/zstatus/socket"\
		zwmsocket 	"$cache_prefix/zwm/socket"]

	namespace export read get
}

proc zstatus::config::get {key configfile} {
	variable defaultfile
	variable config

	if {$configfile == "default"} {
		set configfile $defaultfile
	}

	set value ""
	if [info exists config($key)] {
		set value $config($key)
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

	set config(leftside) {deskmode separator desklist separator\
					deskname separator wintitle}
	set config(rightside) {datetime}
	array set mailboxes {}

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
					set config($key) $value
				} elseif {$context == "maildir"} {
					if [info exists mailboxes($index)] {
						array set mailbox $mailboxes($index)
					}
					set mailbox($key) $value
					set mailboxes($index) [array get mailbox]
					array unset mailbox
				} else {
					array set widget $::widgetarray($context)
					set widget($key) $value
					set ::widgetarray($context) [array get widget]
					array unset widget
				}
			}
		}
	}

	# Validate mailboxes
	foreach index [array names mailboxes] {
		array set mailbox $mailboxes($index)
		if ![info exists mailbox(light)] {
			set mailbox(light) black
		}
		if ![info exists mailbox(dark)] {
			set mailbox(dark) LightGray
		}
		if {![info exists mailbox(name)] || ![info exists mailbox(path)]} {
			array unset mailboxes $index
		} else {
			set mailboxes($index) [array get mailbox]
		}
		array unset mailbox
	}
	set config(mailboxes) [array get mailboxes]

	return [array get config]
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
