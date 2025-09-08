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

	# Array of available widgets
	array set widgets {\
	    arcsize { type lwidget source zstatus::system::arcsize\
			proc system::set_arcsize setup system::setup\
			font normal light black dark LightGray }\
	    datetime { type string source zstatus::datetime\
			proc set_datetime format {%d %b %H:%M}\
			font normal light black dark LightGray}\
	    desklist { type lwidget source zstatus::desktop::desklist\
			setup desktop::setup\
			font normal light black dark LightGray }\
	    deskmode { type lwidget source zstatus::desktop::deskmode\
			setup desktop::setup\
			font normal light black dark LightGray }\
	    deskname { type lwidget source zstatus::desktop::deskname\
			font normal light black dark LightGray }\
	    devices { type transient proc devices::update setup devices::setup\
			settheme devices::set_theme\
			font normal light black dark LightGray }\
	    loadavg { type lwidget source zstatus::system::loadavg\
			proc system::set_loadavg setup system::setup\
			font normal light black dark LightGray }\
	    mail { type transient proc zstatus::mail::update\
			setup mail::setup settheme mail::set_theme\
			font normal light black dark LightGray }\
	    memused { type lwidget source zstatus::system::memused\
			proc system::set_memused setup system::setup\
			font normal light black dark LightGray }\
	    metar { type lwidget source zstatus::metar::report(statusbar)\
			setup metar::setup settheme metar::set_theme delay 10\
			font normal light black dark LightGray }\
	    mixer { type lwidget source zstatus::system::mixer\
			proc system::set_mixer setup system::setup\
			font normal light black dark LightGray }\
	    music { type transient proc music::update\
			setup music::setup settheme music::set_theme\
			font normal light black dark LightGray }\
	    netin { type lwidget source zstatus::system::netin\
			proc system::set_netin setup system::setup interface em0\
			font normal light black dark LightGray }\
	    netout { type lwidget source zstatus::system::netout\
			proc system::set_netout setup system::setup interface em0\
			font normal light black dark LightGray }\
	    sep { type separator light black dark gray }\
	    separator { type separator light black dark gray }\
	    statusbar { type bar light gray90 dark gray20 }\
	    wintitle { type twidget setup desktop::setup maxlength 110\
			font normal light black dark LightGray }}

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
	variable widgets
	variable config

	# List of valid contexts in config file
	set contexts { main arcsize datetime desklist deskmode deskname\
		devices loadavg mail maildir memused metar mixer music\
		netin netout separator statusbar wintitle}

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
