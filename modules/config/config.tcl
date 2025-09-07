#!/usr/bin/env tclsh9.0
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

	# Array of available widgets
	array set widgets {\
	    arcsize { type var source zstatus::arcsize proc set_arcsize\
			font normal light black dark LightGray }\
	    datetime { type var source zstatus::datetime proc set_datetime\
			format {%d %b %H:%M} font normal light black dark LightGray}\
	    desklist { type var source zstatus::desklist\
			font normal light black dark LightGray }\
	    deskmode { type var source zstatus::deskmode\
			font normal light black dark LightGray }\
	    deskname { type var source zstatus::deskname\
			font normal light black dark LightGray }\
	    devices { type transient proc devices::update\
			font normal light black dark LightGray }\
	    loadavg { type var source zstatus::loadavg proc set_loadavg\
			font normal light black dark LightGray }\
	    mail { type transient proc zstatus::mail::update\
			font normal light black dark LightGray }\
	    memused { type var source zstatus::memused proc set_memused\
			font normal light black dark LightGray }\
	    metar { type widget source zstatus::metar::report(statusbar)\
			delay 10 font normal light black dark LightGray }\
	    mixer { type var source zstatus::mixer proc set_mixer\
			font normal light black dark LightGray }\
	    music { type transient proc music::update\
			font normal light black dark LightGray }\
	    netin { type var source zstatus::netin proc set_netin\
			interface em0 font normal light black dark LightGray }\
	    netout { type var source zstatus::netout proc set_netout\
			interface em0 font normal light black dark LightGray }\
	    separator { type separator light black dark gray }\
	    statusbar { type bar light gray90 dark gray20 }\
	    wintitle { type text ref wintitle font normal\
			maxlength 110 font normal light black dark LightGray }}

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
		set lines [zstatus::read_file $configfile]
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
	variable widgets
	variable config

	# List of valid contexts in config file
	set contexts { main arcsize datetime desklist deskmode deskname\
		devices loadavg mail maildir memused metar mixer music\
		netin netout separator statusbar wintitle}

	# Cant change these from config file
	set immutables {type source ref proc}

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
		set lines [split [zstatus::read_file $configfile] "\n"]
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
					array set widget $widgets($context)
					set widget($key) $value
					set widgets($context) [array get widget]
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
	set config(widgets) [array get widgets]

	return [array get config]
}

package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
